# NOTE: Changes here require a server restart.

module ImgProxy
  # A Rack middleware which proxies media_url(*) requests through ImgProxy.
  #
  # Assuming, you have ImgProxy running as
  #
  #   docker run \
  #     -e IMGPROXY_LOCAL_FILESYSTEM_ROOT=/data \
  #     -e IMGPROXY_WATERMARK_PATH=/watermarks/watermark.svg \
  #     -p 127.0.0.1:2206:8080 \
  #     -v RAILS_ROOT/data/blobs:/data/RAILS_ENV:ro \
  #     -v RAILS_ROOT/config/watermarks:/watermarks:ro \
  #     darthsim/imgproxy:latest
  #
  # you'll need to configure the middleware as:
  #
  #   config.middleware.insert_before 0, ImgProxy::Middleware,
  #     backend: "http://localhost:2206",           # address of ImgProxy server
  #     source:  "local://data/#{Rails.env}",       # path prefix for ActiveStorage files
  #     storage: Rails.root.join("data/variants")   # where to cache transformed variants
  #
  # (these are the defaults).
  #
  # This will, in effect, proxy
  #
  # - from http://localhost:3000/p/{blob_id}/{preset_name}/{checksum}/*
  # - to http://localhost:2206/insecure/{expanded_preset}/plain/local://data/production/{blob_path},
  #
  # with on-the-fly format detection vie the Accept-header. The file is
  # cached locally.
  class Middleware < Rack::Proxy
    TTL = 1.year

    DEFAULT_STORAGE_PATH = if Rails.env.test?
      Rails.root.join("tmp/data-test/variants").freeze
    else
      Rails.root.join("data/variants").freeze
    end

    def initialize(app = nil, opts = {})
      @source = opts.delete(:source) || "local://data/#{Rails.env}"
      raise ArgumentError, "missing :source" if @source.blank?

      @storage = opts.delete(:storage) || DEFAULT_STORAGE_PATH
      raise ArgumentError, "missing :storage" unless @storage.is_a?(Pathname)

      # doesn't work with local caching
      opts[:streaming] = false
      super

      raise ArgumentError, "missing :backend" if @backend.blank?
    end

    def call(env)
      super
    rescue StandardError => err
      raise if Rails.env.development? || Rails.env.test?

      Sentry.capture_exception(err) if defined?(Sentry)
      [502, { "Content-Type" => "text/plain" }, ["Bad Gateway"]]
    end

    def perform_request(env)
      return @app.call(env) unless env["PATH_INFO"].start_with?("/p/")

      blob_id, file_name, preset_name, file_format, dpr = rewrite_path_info(env)
      return [404, { "Content-Type" => "text/plain" }, ["Not Found"]] unless file_name

      cache(blob_id, file_name, preset_name, file_format, dpr) do
        setup_request_env(env)
        status, headers, body = super(env)

        headers = cleanup_response(headers, file_name) if status.to_i == 200
        [status, headers, body]
      end
    end

    private

    def rewrite_path_info(env) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # hostport/p/{blob_id}/{preset_name}/{checksum}/{file_name}
      _, _, blob_id, preset_name, checksum, file_name = env["PATH_INFO"].split("/")
      return unless PRESETS.key?(preset_name)
      return if file_name.blank? # legacy path without checksum

      # construct "local://data/production/aa/bb/aabbcdefghi"
      # from blob_id="aabbcdefghi" and @source="local://data/production"
      blob_path   = File.join(@source, blob_id[0..1], blob_id[2..3], blob_id)
      dpr         = 1
      file_format = ImgProxy.extract_format_from_preset(preset_name) ||
        ImgProxy.guess_preferred_image_format(env["HTTP_ACCEPT"])

      # device pixel resolution
      if (m = file_name.match(/(.*?)@(\d)x/))
        file_name = m[1]
        dpr_index = SUPPORTED_DPR_VALUES.index(m[2].to_i) || -1
        dpr       = SUPPORTED_DPR_VALUES[dpr_index]
      end

      return unless ImgProxy.verify_checksum(blob_id, preset_name, file_name, checksum)

      preset  = PRESETS.fetch(preset_name).to_s
      preset += "/format:#{file_format}"
      preset += "/dpr:#{dpr}" if dpr > 1

      env["HTTP_X_ORIGINAL_PATH"] = env["PATH_INFO"]
      env["PATH_INFO"]            = File.join("/insecure", preset, "plain", blob_path)

      [blob_id, file_name, preset_name, file_format, dpr]
    end

    def setup_request_env(env)
      env["HTTP_HOST"]   = @backend.host
      env["HTTP_PORT"]   = @backend.port.to_s
      env["HTTPS"]       = @backend.scheme == "https" ? "on" : "off"
      env["SCRIPT_NAME"] = ""
      env["HTTP_COOKIE"] = nil
    end

    def cleanup_response(headers, file_name)
      headers.reject! { |k| %w[content-length server].include? k.downcase }
      headers.merge!(
        "Vary"                   => "Accept",
        "Content-Disposition"    => %(inline; filename="#{file_name}"),
        "X-Content-Type-Options" => "nosniff",
        "Cache-Control"          => "max-age=#{TTL.to_i}, public",
        "Expires"                => TTL.from_now.httpdate,
      )
      headers
    end

    def cache(blob_id, file_name, preset_name, file_type, dpr)
      file_type = "jpeg" if file_type == "jpg"
      blob_path = @storage.join(blob_id[0..1], blob_id[2..3], blob_id, "#{preset_name}@#{dpr}.#{file_type}")

      if blob_path.exist?
        body    = blob_path.read(mode: "rb")
        headers = cleanup_response({
          "Content-Type" => "image/#{file_type}",
          "Content-Dpr"  => ("#{dpr}.0" if dpr > 1),
        }.compact, file_name)

        return [200, headers, [body]]
      end

      status, headers, body = yield

      blob_path.dirname.tap { |dir| dir.mkpath unless dir.exist? }
      blob_path.open("wb") { |f| f.write body[0] }

      [status, headers, body]
    end
  end
end
