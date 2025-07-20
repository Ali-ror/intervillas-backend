PayPal::SDK.configure do |config|
  config.mode = Rails.env.production? ? "live" : "sandbox"

  if (creds = Rails.application.credentials.paypal)
    config.client_id     = creds[:client_id]
    config.client_secret = creds[:client_secret]
  end

  # certificate embedded in the Gem has expired + Gem is EOL...
  config.ssl_options = { ca_file: nil }
end

PayPal::SDK.logger = Rails.logger
