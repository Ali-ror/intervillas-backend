require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.ignore_localhost     = true
  config.hook_into :webmock
  config.ignore_hosts "texd"

  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == "ASCII-8BIT" ||
      !http_message.body.valid_encoding?
  end

  config.default_cassette_options = {
    record: :new_episodes,
  }

  config.configure_rspec_metadata!
end
