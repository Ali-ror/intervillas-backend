RSpec.configure do |config|
  config.before do |example|
    Rails.logger.debug { "RUNNING SPEC: " + example.full_description }
    Rails.logger.debug { example.location }
  end
end
