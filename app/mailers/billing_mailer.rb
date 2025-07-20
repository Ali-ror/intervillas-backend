class BillingMailer < ApplicationMailer
  include Exposer

  helper_method :imessage, :rentable

  expose(:owner)    { rentable.owner }
  expose(:booking)  { inquiry.booking }
  expose(:customer) { inquiry.customer }

  def boat_owner_billing(inquiry:, message:, to:, **)
    rentable_owner_billing(inquiry, message, to, inquiry.boat)
  end

  def villa_owner_billing(inquiry:, message:, to:, **)
    rentable_owner_billing(inquiry, message, to, inquiry.villa)
  end

  def tenant_billing(inquiry:, message:, to:, **)
    @imessage = message
    @inquiry  = inquiry
    @rentable = inquiry.villa

    raise Bookings::External::Error, "external" if inquiry.external

    attachments["billing.pdf"] = File.read(_tenant_billing.pdf.save)

    mail(
      to:         to,
      subject:    inquiry_subject("billing_mailer.tenant_billing.subject"),
      store_with: message,
    )
  end

  def clearing_report(clearing:, to:, **)
    @clearing = clearing
    @date_str = I18n.l(@clearing.month, format: "%Y-%m")

    @clearing.with_compiled_pdf do |pdf|
      attachments["billings-#{@clearing.contact.to_s.parameterize}-#{@date_str}.pdf"] = pdf
    end

    mail(
      to:         to,
      bcc:        "info+kopie@intervillas-florida.com",
      subject:    I18n.t("billing_mailer.clearing_report.subject", date: @date_str),
      store_with: message,
    )
  end

  private

  attr_reader :inquiry, :imessage, :rentable

  def signature_template
    if defined?(@clearing) && @clearing.present?
      if @clearing.month >= Rails.configuration.x.corporate_switch_date
        "corp"
      else
        "gmbh"
      end
    else
      super
    end
  end

  def rentable_owner_billing(inquiry, message, to, rentable)
    @imessage = message
    @inquiry  = inquiry
    @rentable = rentable

    attachments["billing.pdf"] = File.read(_owner_billing.pdf.save)

    I18n.with_locale :en do
      mail(
        to:            to,
        subject:       inquiry_subject("billing_mailer.owner_billing.subject"),
        template_path: "billing_mailer",
        template_name: "owner_billing",
        store_with:    message,
      )
    end
  end

  def _owner_billing
    @owner_billing ||= booking.to_billing.owner_billings.find { |ob|
      ob.recipient == imessage.recipient
    }
  end

  def _tenant_billing
    @tenant_billing ||= booking.to_billing.tenant_billing
  end
end
