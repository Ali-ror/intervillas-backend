class PaymentMailerPreview < ActionMailer::Preview
  include DigineoExposer::Memoizable

  memoize(:inquiry, private: true) { message.inquiry }
  memoize(:messages, private: true) do
    Message
      .joins(:booking, inquiry: :customer)
      .where(customers: { locale: I18n.locale })
      .where(template: params[:action])
  end

  memoize(:message, private: true) do
    m = if params["id"]
      messages.where(inquiry_id: params[:id]).first
    else
      messages.last
    end

    m || messages.build(inquiry: Inquiry.find(params[:id]))
  end

  def payment_mail_reloaded
    PaymentMailer.payment_mail_reloaded \
      inquiry: inquiry,
      message: message,
      to:      inquiry.customer.email
  end

  def payment_reminder
    PaymentMailer.payment_reminder \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  def payment_prenotification
    PaymentMailer.payment_prenotification \
      inquiry: inquiry,
      to:      inquiry.customer.email
  end

  include I18nPreview
end
