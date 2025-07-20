require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Intervillas
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.active_support.cache_format_version    = 7.0
    config.active_support.disable_to_s_conversion = true

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Europe/Berlin"
    # config.eager_load_paths << Rails.root.join("extras")

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path                += Dir[Rails.root.join("config/locales/**/*.{rb,yml}").to_s]
    config.i18n.enforce_available_locales = false
    config.i18n.default_locale            = :de
    config.i18n.fallbacks                 = [I18n.default_locale]
    config.i18n.available_locales         = %i[de en]
    # Globalize.fallbacks = {:en => [:de], :de => [:en]}

    config.after_initialize do |app|
      Geocode.geocoder = Graticule.service(:google).new app.credentials.google_maps_geocoding_key

      # Provide a default for the :host parameter to the router (see initalizers/0_env.rb).
      # This stops `url_helpers.*_url` to complain about "Missing host to link to!".
      #
      # cf. https://stackoverflow.com/a/72992100/766783
      app.routes.default_url_options = app.config.action_mailer.default_url_options
    end

    config.generators do |g|
      g.fixture_replacement :factory_bot
      g.assets false
      g.helper false
      g.system_tests nil
    end

    config.active_record.schema_format = :sql

    # Use the same queue for analysis and deletion of media.
    config.active_storage.queues.analysis = :media
    config.active_storage.queues.purge    = :media

    # Add volatile information back to AR#cache_key (this was the default upto and including
    # Rails 5.2). We do rely on this behaviour in various places.
    config.active_record.cache_versioning            = false
    config.active_record.collection_cache_versioning = false

    config.x.corporate_switch_date = "2025-01-01".to_datetime.beginning_of_day
  end
end
