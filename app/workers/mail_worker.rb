class MailWorker
  include Sidekiq::Worker
  sidekiq_options(
    backtrace:  true,
    queue:      :mailers,
  )

  def perform(clazz, id, method, *args)
    clazz.constantize.find(id).send "sync_#{method}", *args
  rescue ActiveRecord::RecordNotFound => err
    Sentry.capture_exception(err)
  rescue Bookings::External::Error => err
    Sentry.capture_exception(err)
  end
end
