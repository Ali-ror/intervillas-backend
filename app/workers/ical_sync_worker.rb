class IcalSyncWorker
  include Sidekiq::Worker

  sidekiq_options(
    backtrace:        true,
    retry:            3,
    lock:             :until_and_while_executing, # limit one worker per calendar
    lock_args_method: ->(args) { [args.first] },  # calendar ID is first (and only) argument
    lock_timeout:     2,                          # lock acquisition timeout in seconds
    on_conflict:      :log,                       # simply ignore duplicate jobs
  )

  def perform(calendar_id)
    Ical::Sync.run Calendar.find(calendar_id)
  end
end
