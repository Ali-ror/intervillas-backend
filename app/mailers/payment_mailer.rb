class PaymentMailer < ApplicationMailer
  helper_method :deadlines, :payments, :difference, :difference?, :overpaid?,
    :imessage, :payments_booking_url, :inquiry,
    :last_payment_date, :outstanding_payment

  expose(:customer)          { inquiry.customer }
  expose(:booking)           { inquiry.booking }
  expose(:payment_deadlines) { inquiry.payment_deadlines }
  expose(:rentables)         { inquiry.rentable_names.join(" / ") }
  expose(:current_currency)  { inquiry.currency }

  def payment_mail_reloaded(inquiry:, message:, to:, **)
    @inquiry  = inquiry
    @imessage = message

    raise Bookings::External::Error, "external" if inquiry.external

    mail(
      to:         to,
      subject:    inquiry_subject("payment_mailer.payment_mail_reloaded.subject"),
      store_with: message,
    )
  end

  def payment_reminder(inquiry:, to:, message: nil, **)
    @inquiry = inquiry

    raise Bookings::External::Error, "external" if inquiry.external

    mail(
      to:         to,
      subject:    inquiry_subject("payment_mailer.payment_reminder.subject"),
      store_with: message,
    )
  end

  def payment_prenotification(inquiry:, to:, message: nil, **)
    @inquiry = inquiry

    raise Bookings::External::Error, "external" if inquiry.external

    mail(
      to:         to,
      subject:    inquiry_subject("payment_mailer.payment_prenotification.subject"),
      store_with: message,
    )
  end

  private

  attr_reader :inquiry, :imessage

  module PaymentDeadlinesView
    Receipt = Struct.new :name, :date, :sum # rubocop:disable Lint/StructNewOverride

    def __locale
      I18n.locale
    end

    def deadlines
      payment_deadlines.deadlines.map do |deadline|
        Receipt.new.tap { |dl|
          dl.name = I18n.t("payments.scope.#{deadline.name}", locale: __locale)
          dl.date = I18n.l(deadline.date.to_date, locale: __locale)
          dl.sum  = deadline.display_sum
        }
      end
    end

    def payments
      payment_deadlines.payments.select(&:paid?).map do |payment|
        Receipt.new.tap { |dl|
          dl.date = I18n.l(payment.paid_on, locale: __locale)
          dl.sum  = payment.paid_sum
        }
      end
    end

    def outstanding_payment # rubocop:disable Metrics/AbcSize
      return @outstanding_payment if defined?(@outstanding_payment)

      deadline = payment_deadlines.downpayment_deadline
      if booking && !booking.late? && !deadline.paid?
        @outstanding_payment = Receipt.new.tap { |out|
          out.name = I18n.t("payments.scope.#{deadline.name}", locale: __locale)
          out.date = I18n.l(deadline.date.to_date, locale: __locale)
          out.sum  = deadline.due_balance
        }
        return @outstanding_payment
      end

      deadline = payment_deadlines.remainder_deadline
      if difference > 0
        @outstanding_payment = Receipt.new.tap { |out|
          out.name = I18n.t("payments.scope.#{deadline.name}", locale: __locale)
          out.date = I18n.l(deadline.date.to_date, locale: __locale)
          out.sum  = deadline.due_balance
        }
        return @outstanding_payment
      end

      @outstanding_payment = nil
    end

    def last_payment_date
      last_payment = payment_deadlines.payments.select(&:paid?).max_by(&:paid_on)
      I18n.l(last_payment.paid_on, locale: __locale) if last_payment
    end
  end
  include PaymentDeadlinesView

  delegate :difference, to: :payment_deadlines

  def difference?
    difference >= 0
  end

  def overpaid?
    difference < 0
  end

  def payments_booking_url
    payments_url \
      token:     inquiry.token,
      subdomain: subdomain
  end
end
