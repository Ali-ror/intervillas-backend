module CronWorker
  class TravelMailReminder < Base
    every 2.hours

    # Erinnerungen 2 Wochen vor Reisebeginn (enthält auch Safe-Code)
    def perform_non_staging
      Booking.need_travel_mail.each(&:deliver_travel_mail)
    end
  end
end
