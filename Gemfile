source "https://rubygems.org"

git_source(:digineo) { |name| "gitlab@git.digineo.de:#{name}.git" }
git_source(:github)  { |name| "https://github.com/#{name}.git"    }

gem "rails",                      "~> 7.0.0"
gem "puma"

#
# Databases
#
gem "composite_primary_keys",     "~> 14.0" # for Rails 7.0.x
gem "pg"
gem "dalli"                       # memcached adapter
gem "maxminddb"                   # GeoIP database

#
# Asset handling, frontend
#
gem "erubis"
gem "formtastic-bootstrap",       github: "MethodologyDev/formtastic-bootstrap", branch: "formtastic-v4-support"
gem "formtastic"
gem "haml"
gem "jbuilder"
gem "localized_country_select",   ">= 0.10.2"
gem "rails-i18n",                 "~> 7.0.0" # for Rails 7.0.0
gem "will_paginate"
gem "vite_rails"

#
# Model enhancements, validations
#
gem "acts_as_list"
gem "addressable"
gem "comma"
gem "globalize"
gem "inherited_resources"
gem "model_form",                 path: "vendor/gems/model_form"
gem "strip_attributes"
gem "validate_url"
gem "validates_email_format_of"
gem "virtus-multiparams"

#
# Other libraries
#
gem "babosa"
gem "cancancan"
gem "cancan-inherited_resources"  # XXX: must be loaded after cancancan
gem "devise",                     "~> 4.4", "!= 4.4.2" # https://github.com/plataformatec/devise/issues/4808
gem "devise-two-factor"
gem "digineo_exposer",            path: "vendor/gems/exposer"
gem "faraday-encoding"
gem "faraday-follow_redirects"
gem "faraday"
gem "graticule",                  github: "digineo/graticule"
gem "has_scope"
gem "icalendar"
gem "json"
gem "kramdown"                     # Markdown-Renderer, nicht nur für doc/pages/*.md
gem "mail"
gem "mini_magick"
gem "mini_scheduler"
gem "net-imap"
gem "paypal-sdk-rest"
gem "rack-cors"
gem "rack-proxy"
gem "recaptcha"
gem "rqrcode_core"
gem "rubyzip",                    require: "zip"
gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"
gem "sidekiq",                    "< 7" # 7.x requires Redis 6.2+
gem "sidekiq-throttled"
gem "sidekiq-unique-jobs"
gem "sinatra",                    require: false
gem "sorted_set"
gem "texd"
gem "usps"

group :development, :test do
  gem "dotenv"
  gem "factory_bot_rails"
  gem "mida"                      # Schema.org-Microdata-Parser
  gem "debug"
  gem "rspec-core"
  gem "rspec-expectations"
  gem "rspec-instafail",          require: false
  gem "rspec-its"
  gem "rspec-mocks"
  gem "rspec-rails"
  gem "rspec-retry"
  gem "rspec-support"
  gem "rspec"

  # ist nur ein CLI-Tool, und das Laden hat Seiteneffekte (lädt z.B.
  # i18n-rails, was teilw. unsere Locales überschreibt)
  gem "i18n-tasks",               require: false

  # pin rubocop to a specific versions, as newer version WILL
  # complain about unconfigured cops
  gem "rubocop",                  "~> 1.72.0", require: false
  gem "rubocop-capybara",         "~> 2.21.0", require: false
  gem "rubocop-factory_bot",      "~> 2.26.0", require: false
  gem "rubocop-rails",            "~> 2.30.0", require: false
  gem "rubocop-rake",             "~> 0.7.0",  require: false
  gem "rubocop-rspec",            "~> 3.5.0",  require: false
  gem "rubocop-rspec_rails",      "~> 2.30.0", require: false
end

group :development do
  gem "annotate"
  gem "better_errors",            "~> 2.9", "!= 2.10.0" # https://github.com/BetterErrors/better_errors/issues/516
  gem "binding_of_caller"
  gem "letter_opener"
  gem "rails-erd"
end

group :test do
  gem "capybara-email",           github: "DockYard/capybara-email"
  gem "capybara"
  gem "database_cleaner",         require: false
  gem "faker"
  gem "launchy"
  gem "libxml-ruby"               # (undeclared!) dependency of rspreadsheet
  gem "pdf-reader"
  gem "rails-controller-testing"
  gem "rspreadsheet"
  gem "selenium-webdriver"        # XXX: v4.9.1+ require Ruby 3.0
  gem "shoulda-matchers",         "~> 5.1.0" # 6.x requires Ruby 3.0.5 (Ubuntu 22.04 provides 3.0.2)
  gem "simplecov"
  gem "timecop"
  gem "vcr"
  gem "webmock"
end

group :deployment do
  gem "bcrypt_pbkdf"
  gem "capistrano-rails"
  gem "capistrano",               "~> 3.3"
  gem "ed25519"
end

group :production do
  gem "scout_apm"
end
