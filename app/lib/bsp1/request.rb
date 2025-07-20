class Bsp1::Request
  SECRETS = Rails.application.credentials.bsp1!

  STATIC_PARAMS = {
    portalid: SECRETS.fetch(:portal_id),
    mid:      SECRETS.fetch(:merchant_id),
    aid:      SECRETS.fetch(:sub_account_id),
    mode:     Rails.env.production? ? "live" : "test",
  }.freeze

  include ActiveModel::Validations

  attr_accessor :amount, :language
  validates_presence_of :amount, :language

  def submit
    raise_validation_error if invalid?

    response = api.post("post-gateway/", build_params)
    Bsp1::Response.new(response.body)
  end

  def bsp1_params(**in_params)
    params = STATIC_PARAMS.merge(in_params)

    params[:api_version] = "3.11"
    params[:encoding]    = "UTF-8"
    params[:amount]      = amount
    params[:language]    = language

    key = SECRETS.fetch(:key)

    params.merge(
      key: Digest::MD5.hexdigest(key),
    )
  end

  def self.hashed_params(**in_params)
    params = STATIC_PARAMS.merge(in_params)

    key  = SECRETS.fetch(:key)
    hash = OpenSSL::HMAC.hexdigest(
      "sha384", key,
      params.reject { |k, _v| %i[lastname country language].include?(k) }.sort.map(&:second).join
    )

    params.merge(
      hash: hash,
    )
  end

  def self.callback_host
    subdomain = case Rails.env
    when "production"
      I18n.locale == :en ? "en" : "www"
    when "staging"
      I18n.locale == :en ? "en.staging" : "www.staging"
    else
      "ipnproxy"
    end

    "https://#{subdomain}.intervillas-florida.com"
  end

  private

  def api
    Faraday.new(url: "https://api.pay1.de/") do |faraday|
      faraday.request :url_encoded
      faraday.use Bsp1::PlainKeyValue
      faraday.response :encoding
      faraday.response :logger, Rails.logger, bodies: true
      faraday.adapter Faraday.default_adapter
    end
  end
end
