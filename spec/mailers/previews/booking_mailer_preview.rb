# Preview all emails at http://localhost:3000/rails/mailers/booking_mailer
class BookingMailerPreview < ActionMailer::Preview
  include DigineoExposer::Memoizable

  memoize :inquiry, private: true do
    Booking
      .joins(inquiry: :customer)
      .where(customers: { locale: I18n.locale })
      .last
      .inquiry
  end

  def confirmation_mail
    BookingMailer.confirmation_mail \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  def review
    inquiry.prepare_review
    BookingMailer.review \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  def travel
    BookingMailer.travel_mail \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  include I18nPreview
end
