module SentryHelper
  FRONTEND_SENTRY_CONFIG = if Sentry.configuration.enabled_environments.include?(Rails.env)
    format "var SENTRY_CONFIG = %p;", Base64.strict_encode64({
      dsn:         Sentry.configuration.dsn.to_s,
      environment: Rails.env,
      release:     Sentry.configuration.release,
    }.to_json)
  end

  def sentry_integration_tag
    return unless FRONTEND_SENTRY_CONFIG

    tag.script FRONTEND_SENTRY_CONFIG.html_safe # rubocop:disable Rails/OutputSafety
  end
end
