class InquiryMailer < ApplicationMailer
  helper_method :new_booking_url

  expose(:customer) { inquiry.customer }

  def submission_mail(inquiry:, to:, message: nil, **)
    raise Bookings::External::Error, "external" if inquiry.external

    @inquiry   = inquiry
    villa_name = inquiry.villa_inquiry.villa_name

    mail(
      to:         to,
      subject:    inquiry_subject("inquiry_mailer.submission_mail.subject", villa_name: villa_name),
      store_with: message,
    )
  end

  def reminder_mail(inquiry:, to:, message: nil, **)
    raise Bookings::External::Error, "external" if inquiry.external

    @inquiry   = inquiry
    villa_name = inquiry.villa_inquiry.villa_name

    mail(
      to:         to,
      subject:    inquiry_subject("inquiry_mailer.reminder_mail.subject", villa_name: villa_name),
      store_with: message,
    )
  end

  private

  attr_reader :inquiry

  def new_booking_url
    super token: inquiry.token, subdomain: subdomain
  end
end
