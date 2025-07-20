require "sidekiq/throttled"

dbnum = {
  "production"  => 0,
  "development" => 1,
  "test"        => 2,
  "staging"     => 3,
}.fetch(Rails.env)

redis_url = ENV.fetch("REDIS_URL") {
  ENV["CI"] ? "redis://redis:6379" : "redis://localhost:6379/#{dbnum}"
}

redis_options = { url: redis_url }

Sidekiq.configure_server do |config|
  config.redis = redis_options

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = redis_options

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.strict_args!
ActiveJob::Base.queue_adapter = :sidekiq

MiniScheduler.configure do |config|
  # An instance of Redis. See https://github.com/redis/redis-rb
  config.redis = Redis.new(redis_options)
end

if Sidekiq.server? && defined?(Rails)
  Rails.application.config.after_initialize do
    MiniScheduler.start
  end
end
