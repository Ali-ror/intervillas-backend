module MyBookingPal
  #
  # Used for MyBookingPal, to avoid a stampede, e.g. when reordering images
  # would created dozens of image update jobs.
  #
  # Usually, when you want to call
  #
  #     MyBookingPal::ThrottledWorker.perform_async("MyBookingPal::Async::ImagePusher", villa.product.id)
  #
  # but you expect to create more than a few of such throttled requests,
  # you may want to use
  #
  #     MyBookingPal::BulkheadWorker.perform_in(2.minutes, "MyBookingPal::Async::ImagePusher", villa.product.id)
  #
  # instead.
  #
  # This will wait 2 minutes before it performs the ImagePusher job, but any
  # time you'll schedule another BulkheadWorker, the timer resets.
  #
  class BulkheadWorker
    include Sidekiq::Worker

    sidekiq_options(
      lock:         :until_and_while_executing,
      lock_timeout: 2,
      on_conflict:  {
        client: :log,
        server: :replace,
      },
    )

    def perform(class_name, *args)
      ThrottledWorker.perform_async(class_name, *args)
    end
  end
end
