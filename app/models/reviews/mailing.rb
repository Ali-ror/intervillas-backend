module Reviews::Mailing
  extend ActiveSupport::Concern

  included do |base|
    belongs_to :message, optional: true # optional, weil NULL erlaubt

    delegate :customer, to: :booking
  end

  def deliver_review_mail
    unless message
      self.message = create_message! \
        inquiry:   booking.inquiry,
        template:  "review",
        recipient: booking.customer
      save!
    end

    message.deliver!
  end

  def mail_sent?
    message && message.sent_at?
  end

end
