module CronWorker
  class CalendarUpdate < Base
    every 15.minutes

    def perform_non_staging
      active_villa_ids = Villa.active.select(:id)

      Calendar.where(villa_id: active_villa_ids).select(:id).find_each do |calendar|
        IcalSyncWorker.perform_async calendar.id
      end
    end
  end
end
