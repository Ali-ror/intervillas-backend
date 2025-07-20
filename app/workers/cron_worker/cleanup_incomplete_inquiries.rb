module CronWorker
  class CleanupIncompleteInquiries < Base
    daily at: 1.hour

    # täglich unvollständigen Buchungen löschen, die vor mehr als einer Wochen angelegt wurden
    def perform_non_staging
      Inquiry.where("customer_id is null and created_at < ?", 1.week.ago).destroy_all
    end
  end
end
