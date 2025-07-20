ActiveSupport.on_load(:action_view) do
  Texd.configure do |config|
    config.error_format  = "json"
    config.helpers       = [Billing::Template::Helpers]
    config.error_handler = ->(err, _doc) {
      Sentry.set_context "texd", { details: err.details }
      Sentry.capture_exception(err)

      raise err
    }
  end
end
