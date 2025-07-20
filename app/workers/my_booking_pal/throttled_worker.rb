module MyBookingPal
  #
  # Used for MyBookingPal, to keep within their rate limit.
  #
  # We'll produce nightly bursts of price updates (with multiple requests
  # per Villa/Product), which need to be interweaved with regular pricing
  # updates (e.g. when an Inquiry becomes a Booking).
  #
  class ThrottledWorker
    include Sidekiq::Worker
    include Sidekiq::Throttled::Worker

    sidekiq_throttle(
      concurrency: { limit: 5 },
      threshold:   { limit: 5, period: 1.second },
    )

    def perform(class_name, *args)
      class_name.constantize.perform(*args)
    rescue MyBookingPal::RateLimited
      # enforce a pause and retry again
      self.class.perform_in(rand(10..15).seconds, class_name, *args)
    end
  end
end
