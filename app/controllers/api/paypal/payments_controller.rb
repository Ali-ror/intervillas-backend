class Api::Paypal::PaymentsController < ApiController
  # stößt Zahlungsvorgang an, leitet zu PayPal weiter
  def create
    if payment_authorization.valid?
      redirect_to payment_authorization.url, allow_other_host: true
    else
      flash["danger"] = t("payments.information.error")
      redirect_to payments_url(token: inquiry.token)
    end
  rescue InquiryPaymentMediator::UnexpectedAmount
    flash["danger"] = t("payments.information.unexpected_amount")
    redirect_to payments_url(token: inquiry.token)
  end

  # User kommt von Paypal zurück, hat Zahlung getätigt
  def complete
    if payment_mediator.execute(params[:paymentId], params[:PayerID])
      flash["success"] = t("payments.information.completed")
    else
      flash["danger"] = t("payments.information.error")
    end

    redirect_to payments_url(token: inquiry.token)
  rescue InquiryPaymentMediator::UnexpectedError => err
    Sentry.capture_exception(err)
    flash["danger"] = t("payments.information.error")
    redirect_to payments_url(token: inquiry.token)
  end

  # User kommt von Paypal zurück, hat Zahlung abgebrochen
  def cancel
    payment_mediator.cancel(params[:token])

    flash["warning"] = t("payments.information.cancelled")
    redirect_to payments_url(token: inquiry.token)
  end

  private

  memoize(:inquiry,          private: true) { Inquiry.find_by! token: params[:inquiry_token] }
  memoize(:payment_mediator, private: true) { InquiryPaymentMediator.new inquiry }

  memoize :payment_authorization, private: true do
    payment_mediator.authorize(expected_amount: expected_amount, modus: modus)
  end

  def modus
    params.fetch(:modus)
  end

  def expected_amount
    params.fetch(:amount)
  end
end
