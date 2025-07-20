module CronWorker
  class PayoutReminder < Base
    daily at: 6.hours

    # Erinnerung an vorzeitigen Auszahlungen (support#719)
    def perform_non_staging
      ids = VillaInquiry
        .joins(inquiry: :booking, villa: :owner)
        .where(QUERY)
        .pluck(:inquiry_id)

      AdminMailer.payout_reminder(ids).deliver_later if ids.size > 0
    end

    QUERY = <<~SQL.squish.freeze
          contacts.payout_reminder_days is not null
      and villa_inquiries.start_date - contacts.payout_reminder_days * interval '1 day' = current_date
    SQL
    private_constant :QUERY
  end
end
