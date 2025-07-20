module MyBookingPal
  # if Rails.env.development?
  #   ::Net::HTTP.send(:include, Module.new {
  #     def debug_output=(out)
  #       @debug_output = out
  #     end
  #   })
  # end

  class Client # rubocop:disable Metrics/ClassLength
    CONFIG = begin
      base = Rails.application.credentials.fetch(:my_booking_pal, {
        endpoint:  "https://apidemo.mybookingpal.com",
        api_token: "RuM12ZnLRzMWnb0k0ifdC4UbliDREm07phvJuBlA",
        system:    {
          username: "INTERVILLASPMS@pms.com",
          password: "iNt3rVas*06182023",
        },
      }).with_indifferent_access

      base[:manager] ||= begin
        salt        = "mybookingpal:#{Rails.env}"
        derived_key = Rails.application.key_generator.generate_key(salt, 24)
        encoded_key = Base64.urlsafe_encode64(derived_key).tr("=", "")

        username = "intervillas+#{Rails.env}@digineo.de"
        contact  = Rails.env.production? ? "info@intervillas-florida.com" : username

        { contact:, username:, password: encoded_key }.freeze
      end

      base.freeze
    end

    # Maximum request size for API requests. The documented value of "200 KB" is
    # ambiguous and could mean either 200 kB or 200 KiB. It is also unclear whether
    # this includes the HTTP header. Also, also: as the payload size grows, their
    # servers tend to run into timout, hence we'll settle for 150 KiB as maximum.
    MAX_CHUNK_SIZE = 150.kilobytes

    def initialize
      @system_token = Token.new(:system) {
        login! :system
      }

      @manager_token = Token.new(:manager) {
        find_or_create_pm!
        login! :manager
      }
    end

    def relog!
      @system_token.update_token
      @manager_token.update_token

      true
    end

    def channel_connector_url
      return unless Rails.env.production?

      tok = CGI.escape manager_token
      "https://wizardiframe.channelconnector.com/jwt/#{tok}"
    end

    # Needs to be called once in a while on the production server (inofficial API;
    # requires production credentials). The result should be placed in the repo at
    # app/javascript/admin/my_booking_pal/amenities.ts.
    #
    # See RAILS_ROOT/lib/tasks/my_booking_pal.rake
    def fetch_amenities
      return unless Rails.env.production?

      uri = URI.parse("https://mybookingpal.com/xml/services/rest/supplierapi/product/amenities")
      res = Net::HTTP.get_response uri, { "jwt" => manager_token }
      raise APIError, res.body unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body).fetch("data")
    end

    def pm_details
      id = find_pm.fetch("id")
      get("/pm/#{id}", privileged: true).first
    end

    def update_pm(data: PM_DATA)
      create_or_update_pm(find_pm&.fetch("id"), data:)
      @pm = nil
      find_pm
    end

    def info
      get("/info", privileged: true).first
    end

    def update_info(base_url:)
      post("/info", privileged: true, body: {
        data: {
          asyncPush:       File.join(base_url, "api/my_booking_pal/notification"),
          reservationLink: File.join(base_url, "api/my_booking_pal/reservation"),
          useJson:         true,
        },
      })
    end

    # Fetches (GET) data from the server.
    #
    # @param [String] path Path to endpoint.
    # @param [Hash] headers Extra header values.
    # @param [Hash] params Extra URL parameters.
    # @param [Boolean] privileged
    #   When truthy, the request is made with system privileges.
    def get(path, headers: nil, params: nil, privileged: false)
      make_request :get, path, params:, headers:, token: (privileged ? system_token : manager_token)
    end

    %i[put post delete].each do |verb|
      # Sends data via POST, PUT or DELETE request.
      #
      # @param [String] path Path to endpoint.
      # @param [#to_json] data
      #   The actual payload, shorthand for `body: { data: <your payload> }`.
      # @param [#to_json, any] body
      #   Allows more control over the request body. When set, this overrides
      #   the `data` parameter.
      # @param [Hash] headers Extra header values.
      # @param [Hash] params Extra URL parameters.
      # @param [Boolean] privileged
      #   When truthy, the request is made with system privileges.
      define_method(verb) do |path, data: nil, body: { data: }, headers: nil, params: nil, privileged: false|
        make_request verb, path, headers:, params:, body:, token: (privileged ? system_token : manager_token)
      end
    end

    private

    #
    # Authentication and tokens
    #

    def system_token
      @system_token.token
    end

    def manager_token
      @manager_token.token
    end

    def login!(user)
      cfg = CONFIG.fetch(user)

      response = make_request :get, "/authc/login",
        token:  nil,
        params: {
          username: cfg.fetch(:username),
          password: cfg.fetch(:password),
        }

      response.fetch("token") {
        raise TokenMissing, "token not found in #{response.inspect}"
      }
    end

    def find_pm
      @pm ||= begin
        emails = CONFIG.fetch(:manager).values_at(:contact, :username).uniq

        get("/pmlist", privileged: true).find { |mgr|
          emails.include? mgr["emailAddress"]
        }
      end
    end

    def find_or_create_pm!
      create_or_update_pm(nil) unless find_pm
      true
    end

    def create_or_update_pm(id, data: PM_DATA)
      method, path = if id.present?
        [:put, "/pm/#{id}"]
      else
        [:post, "/pm"]
      end

      make_request method, path,
        body:  { data: },
        token: system_token
    end

    #
    # Low-level stuff
    #

    PM_DATA = Rails.application.config_for("mybookingpal_pm").freeze
    private_constant :PM_DATA

    CONNECTION_CONFIG = {
      open_timeout:  15, # 5 was far too low
      read_timeout:  65, # remote produces a GatewayTimeout after ~55s
      write_timeout: 15, # our payload is at most MAX_CHUNK_SIZE bytes small
      ssl_timeout:   5,  # should be quick
      debug_output:  $stderr,
    }.freeze
    private_constant :CONNECTION_CONFIG

    def make_request(method, path, headers: nil, params: nil, body: nil, token: manager_token)
      req, uri = build_request(method, path, headers:, params:, body:, token:)

      priv = token.nil? ? nil : token == system_token
      RequestLog.capture(req, uri, method, path, priv, **CONNECTION_CONFIG) { |res|
        case res
        when Net::HTTPSuccess
          parse_response(res)
        when Net::HTTPTooManyRequests
          raise RateLimited, res
        else
          raise APIError, res.body
        end
      }
    end

    Response = Struct.new(:payload, :message, keyword_init: true)
    private_constant :Response

    def parse_response(res)
      ct,  = res.fetch("Content-Type", "").downcase.split(";").map(&:strip)
      body = res.body
      body.force_encoding "UTF-8"

      return Response.new(payload: body) if ct != "application/json" || body.length < 2

      json = JSON.parse(body)
      if json.fetch("is_error", false)
        msg = json.fetch("errorMessage")
        raise APIError, Array.wrap(msg).join("; ")
      end

      Response.new(
        payload: json.fetch("data", json),
        message: json.fetch("message", nil),
      )
    end

    DEFAULT_HEADERS = {
      "User-Agent" => "Intervilla/#{Rails.env} (https://www.intervillas-florida.com)",
      "Accept"     => "application/json",
      "X-API-Key"  => CONFIG.fetch(:api_token),
    }.freeze
    private_constant :DEFAULT_HEADERS

    def build_request(method, path, headers: nil, params: nil, body: nil, token: nil)
      uri = build_uri(path, params, token)
      req = new_request_class(method, uri)

      DEFAULT_HEADERS.merge(headers || {}).compact_blank.each do |k, v|
        req[k] = v
      end

      if body
        req["Content-Type"] = "application/json;charset=UTF-8"
        req.body            = body.is_a?(String) ? body : body.to_json
      end

      [req, uri]
    end

    def build_uri(path, params = nil, token = nil)
      URI.parse(CONFIG.fetch(:endpoint)).tap { |uri|
        uri.path = path

        params     ||= {}
        params[:jwt] = token if token
        next if params.empty?

        q         = params.compact_blank.to_query
        uri.query = uri.query ? "#{uri.query}&#{q}" : q
      }
    end

    def new_request_class(method, uri)
      req_class = case method.to_s.downcase
      when "get"    then Net::HTTP::Get
      when "post"   then Net::HTTP::Post
      when "put"    then Net::HTTP::Put
      when "delete" then Net::HTTP::Delete
      else raise ArgumentError, "unsupported request method: #{method}"
      end

      req_class.new(uri)
    end
  end
end
