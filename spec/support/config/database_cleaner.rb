require "database_cleaner"

# Disable safeguards on CI
#
# https://github.com/DatabaseCleaner/database_cleaner#safeguards
if ENV["CI"] == "1" && (dsn = ENV.fetch("DATABASE_URL", "")).present?
  url                                       = URI.parse(dsn)
  DatabaseCleaner.allow_remote_database_url = url.scheme == "postgresql" && url.host == "postgres"
end

RSpec.configure do |config|
  config.use_instantiated_fixtures  = false
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction
  end

  config.before do |example|
    DatabaseCleaner.strategy = example.metadata[:type] == :feature ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
