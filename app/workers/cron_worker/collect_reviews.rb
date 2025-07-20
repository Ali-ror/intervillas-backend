module CronWorker
  class CollectReviews < Base
    daily at: 12.hours + 15.minutes

    # 10 Tage nach Ende des Urlaubs Kundenmeinungen einholen
    def perform_non_staging
      Inquiry.without_reviews.where(external: false).find_each do |inq|
        inq.prepare_review.deliver_review_mail
      end
    end
  end
end
