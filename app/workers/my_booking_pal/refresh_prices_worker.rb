module MyBookingPal
  class RefreshPricesWorker
    include Sidekiq::Worker
    extend MiniScheduler::Schedule

    daily at: 2.hours + 11.minutes

    def perform
      return if Rails.env.staging?

      MyBookingPal.client.relog!

      MyBookingPal::Product.find_each { |pro|
        pro.update_remote_step!("los_prices")
      }
    end
  end
end
