module CronWorker
  class InquiryReminder < Base
    every 2.hours

    # Erinnerung an offene Anfragen
    def perform_non_staging
      Inquiry
        .complete
        .not_reminded
        .not_booked
        .not_cancelled
        .in_state("submitted")
        .older_than(5.days.ago)
        .find_each(&:remind!)
    end
  end
end
