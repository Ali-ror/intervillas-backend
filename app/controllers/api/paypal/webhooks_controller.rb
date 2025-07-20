class Api::Paypal::WebhooksController < ApiController
  skip_before_action  :verify_authenticity_token
  before_action       :verify_webhook
  wrap_parameters     false

  def create
    webhook = PaypalWebhook.new \
      event_type:     params["event_type"],
      transaction_id: params["resource"]["parent_payment"],
      status:         params["resource"]["state"],
      data:           params.except("controller", "action")

    webhook.save ? head(:ok) : head(:unprocessable_entity)
  end

  private

  def verify_webhook
    v = WebhookVerifier.new(request.raw_post, request.headers)
    logger.debug { v.to_h }
    return if v.valid?

    Sentry.capture_message "invalid webhook", extra: v.to_h
    head(:bad_request)
  end

  WebhookVerifier = Struct.new(:body, :headers) do
    include Memoizable

    memoize(:webhook_id)  { Rails.application.credentials.paypal.fetch(:webhook_id) }
    memoize(:id)          { headers.fetch("HTTP_PAYPAL_TRANSMISSION_ID") }
    memoize(:time)        { headers.fetch("HTTP_PAYPAL_TRANSMISSION_TIME") }
    memoize(:cert_url)    { headers.fetch("HTTP_PAYPAL_CERT_URL") }
    memoize(:signature)   { headers.fetch("HTTP_PAYPAL_TRANSMISSION_SIG") }
    memoize(:algorithm)   { headers.fetch("HTTP_PAYPAL_AUTH_ALGO").sub(/withRSA/i, "") }

    # Cache remote certificate
    memoize(:certificate) do
      cache_key = cert_url.gsub(/[^-\w]/, "_")
      cert_pem  = Rails.cache.fetch(cache_key, expires_in: 1.hour) {
        url = URI.parse(cert_url)
        Net::HTTP.get_response(url).body
      }

      OpenSSL::X509::Certificate.new(cert_pem)
    end

    # This reimplements PayPal::SDK::REST::WebhookEvent.verify with a
    # cache-enabled PayPal::SDK::REST::WebhookEvent.get_cert() method.
    def valid?
      valid_signature? && valid_certificate?
    end

    def to_h
      {
        transmission_id:   id,
        transmission_time: time,
        transmission_sig:  signature,
        cert_url:          cert_url,
        auth_algo:         algorithm,
      }
    end

    private

    def valid_signature?
      PayPal::SDK::REST::WebhookEvent.verify_signature(id, time, webhook_id, body, certificate, signature, algorithm)
    end

    def valid_certificate?
      PayPal::SDK::REST::WebhookEvent.verify_cert(certificate)
    end
  end
  private_constant :WebhookVerifier
end
