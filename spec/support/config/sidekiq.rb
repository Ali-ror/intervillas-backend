# https://github.com/mperham/sidekiq/wiki/Testing

require "sidekiq/testing"

RSpec.configure do |config|
  config.before do |example|
    # Clears out the jobs for tests using the fake testing
    Sidekiq::Worker.clear_all

    inline = (example.metadata[:sidekiq] == :inline) ||
      %i[acceptance feature].include?(example.metadata[:type])

    if inline
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end

  config.before(:suite) do
    Sidekiq.redis { |conn|
      # sidekiq_unique_jobs accumulate keys in redis;
      # while this causes only a warning, it's still noisy.
      conn.del(*conn.keys("uniquejobs:*"))
    }
  end
end
