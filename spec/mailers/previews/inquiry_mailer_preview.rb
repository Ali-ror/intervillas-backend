class InquiryMailerPreview < ActionMailer::Preview
  include DigineoExposer::Memoizable

  memoize :inquiry, private: true do
    Booking
      .joins(inquiry: :customer)
      .where(customers: { locale: I18n.locale })
      .last
      .inquiry
  end

  def submission_mail
    InquiryMailer.submission_mail \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  def reminder_mail
    InquiryMailer.reminder_mail \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  include I18nPreview
end
