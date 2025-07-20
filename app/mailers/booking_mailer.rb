class BookingMailer < ApplicationMailer
  helper_method :boat, :inquiry,
    :downpayment, :downpayment_deadline, :payment_deadline, :remainder,
    :has_villa?, :has_boat?, :has_safe_code?,
    :villa_manager, :boat_manager,
    :review_edit_url, :payments_booking_url

  helper BookingMailerHelper

  expose(:clearing)          { booking.clearing }
  expose(:villa_clearing)    { clearing.for_rentable(:villa) }
  expose(:boat_clearing)     { clearing.for_rentable(:boat) }
  expose(:booking)           { inquiry.booking }
  expose(:customer)          { inquiry.customer }
  expose(:villa_inquiry)     { inquiry.villa_inquiry }
  expose(:villa)             { villa_inquiry.villa }
  expose(:boat_inquiry)      { inquiry.boat_inquiry }
  expose(:current_currency)  { inquiry.currency }

  def confirmation_mail(inquiry:, to:, message: nil, **)
    @inquiry = inquiry
    @boat    = boat_inquiry.boat if boat_inquiry.present?

    raise Bookings::External::Error, "external" if inquiry.external

    mail(
      to:         to,
      bcc:        "info+kopie@intervillas-florida.com",
      subject:    inquiry_subject("booking_mailer.confirmation_mail.subject"),
      store_with: message,
    )
  end

  def travel_mail(inquiry:, to:, message: nil, **)
    @inquiry = inquiry
    @boat    = boat_inquiry.boat if boat_inquiry.present?

    mail(
      to:         to,
      bcc:        "info+kopie@intervillas-florida.com",
      subject:    inquiry_subject("booking_mailer.travel_mail.subject"),
      store_with: message,
    )
  end

  def review(inquiry:, to:, message: nil, **)
    @inquiry = inquiry

    raise Bookings::External::Error, "external" if inquiry.external

    mail(
      to:         to,
      subject:    inquiry_subject("booking_mailer.review.subject"),
      store_with: message,
    )
  end

  private

  attr_reader :boat, :inquiry

  module Payments
    extend ActiveSupport::Concern

    included do
      delegate :payment_deadlines, to: :booking
    end

    def downpayment
      if (dl = payment_deadlines.downpayment_deadline)
        return dl.display_sum.round(2)
      end

      Currency::Value.new(0.0, inquiry.currency)
    end

    def downpayment_deadline
      payment_deadlines.downpayment_deadline.try :date
    end

    def remainder
      payment_deadlines.remainder_deadline.display_sum.round(2)
    end

    def payment_deadline
      payment_deadlines.remainder_deadline.date
    end
  end
  include Payments

  def has_villa?
    villa.present?
  end

  def has_boat?
    boat.present?
  end

  def has_safe_code?
    safe_code.present?
  end

  def safe_code
    villa && villa.safe_code.presence
  end

  def villa_manager
    manager_line_for villa
  end

  def boat_manager
    manager_line_for boat
  end

  def manager_line_for(rentable)
    return if (mgr = rentable.manager).blank?

    I18n.t "#{rentable.class.name.underscore}_manager",
      scope:      "booking_mailer.travel_mail",
      first_name: mgr.first_name,
      last_name:  mgr.last_name,
      phone:      mgr.phone,
      email:      mgr.email_addresses.join(" ")
  end

  def review_edit_url
    edit_villa_review_url \
      id:        booking.review.token,
      villa_id:  villa.to_param,
      subdomain: subdomain
  end

  def payments_booking_url(**options)
    payments_url \
      token:     inquiry.token,
      subdomain: subdomain,
      **options
  end
end
