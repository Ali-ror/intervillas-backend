class BillingMailerPreview < ActionMailer::Preview
  include DigineoExposer::Memoizable

  memoize(:inquiry, private: true) { message.inquiry }
  memoize(:message, private: true) do
    Message
      .joins(:booking, inquiry: :customer)
      .where(customers: { locale: I18n.locale })
      .where(template: "owner_billing")
      .last
  end

  def villa_owner_billing
    BillingMailer.villa_owner_billing \
      inquiry: inquiry,
      message: message,
      to:      inquiry.customer.email
  end

  def boat_owner_billing
    BillingMailer.villa_owner_billing \
      inquiry: inquiry,
      message: message,
      to:      inquiry.customer.email
  end

  def tenant_billing
    BillingMailer.tenant_billing \
      inquiry: inquiry,
      message: message,
      to:      inquiry.customer.email
  end

  def clearing_report
    obr = ClearingReport.new \
      contact:         Contact.find_by(id: 52) || Contact.last,
      reference_month: 2.months.ago.beginning_of_month.to_date

    BillingMailer.clearing_report \
      clearing: obr.send(:clearing),
      to:       obr.contact.emails
  end

  include I18nPreview

  # *_owner_billing gibts nur auf Englisch
  private :villa_owner_billing_de, :boat_owner_billing_de
end
