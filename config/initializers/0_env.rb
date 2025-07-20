def determine_delivery_method!(config)
  delivery = ENV.fetch("RAILS_MAILER_DELIVERY") {
    "sendmail location=/usr/sbin/sendmail" if Rails.env.production?
  }

  case delivery
  when "letter_opener"
    config.delivery_method = :letter_opener
  when /^smtp/ # "smtp host=x port=y", order doesn't matter
    config.delivery_method = :smtp
    config.smtp_settings   = {
      address: delivery[/host=(\S+)/, 1],
      port:    delivery[/port=(\d+)/, 1]&.to_i,
    }.compact
  when /^sendmail/ # "sendmail location=/home/user/bin/mhsendmail"
    config.delivery_method   = :sendmail
    config.sendmail_settings = {
      location:  delivery[/location=(\S+)/, 1].presence,
      arguments: %w[-i], # mail v2.8 requires this to be an array, Rails 5 provides a string
    }.compact
  else
    config.delivery_method = :test
  end
end

def determine_default_url_options!(config)
  # override in env?
  url_options = ENV.fetch("RAILS_DEFAULT_URL_OPTIONS", nil)
  if url_options =~ /host=|port=|protocol=/ # "host=x port=y", order doesn't matter
    config.default_url_options = {
      host:     url_options[/host=(\S+)/, 1],
      port:     url_options[/port=(\d+)/, 1]&.to_i,
      protocol: url_options[/protocol=(https?)/, 1],
    }.compact
    return
  end

  # otherwise apply env-specific defaults
  config.default_url_options = case Rails.env
  when "development"
    { host: "localhost", port: 3000 }
  when "production"
    { host: "www.intervillas-florida.com", protocol: "https" }
  when "staging"
    { host: "staging.intervillas-florida.com", protocol: "https" }
  when "test"
    { host: "localhost", port: 5051 }
  else
    raise ArgumentError, "unknown RAILS_ENV: #{Rails.env}"
  end
end

Rails.application.configure do
  determine_delivery_method!(config.action_mailer)
  determine_default_url_options!(config.action_mailer)
end
