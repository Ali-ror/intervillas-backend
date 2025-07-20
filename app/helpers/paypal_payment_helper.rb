module PaypalPaymentHelper
  def gross(inquiry, scope)
    # bei Buchungen in USD sind die Gebühren bereits enthalten
    return inquiry.deadline_sum(scope) if inquiry.prices_include_cc_fee

    inquiry.calculate_charge(scope).gross
  end

  def paypal_charges(amount)
    charge_calculator(:paypal).add(amount)
  end

  def bsp1_charges(amount)
    charge_calculator(:bsp1).add(amount)
  end

  def paypal_fees
    fees_from_setting :paypal, Setting.paypal_fees_relative
  end

  def bsp1_fees
    fees_from_setting :bsp1, Setting.bsp1_fees_relative
  end

  def fees_from_setting(category, value)
    [
      number_with_precision(value, strip_insignificant_zeros: true),
      h("% + "),
      display_price(charge_calculator(category).absolute),
    ].join.html_safe # rubocop:disable Rails/OutputSafety
  end

  def link_to_paypal_logo
    cc_id = I18n.locale == :de ? "de" : "us"
    href  = "https://www.paypal.com/#{cc_id}/webapps/mpp/paypal-popup"
    opts  = {
      title: t("payments.how_paypal_works"),
      data:  { toggle: :paypal_how_it_works },
    }

    link_to vite_image_tag("images/payments/paypal-logo.svg"), href, opts
  end

  # Mit `amount` werden (im InquiryPaymentMediator) nur einfache Validierungen
  # durchgeführt. Der tatsächliche Wert wird mit `modus` berechnet. Weichen die
  # Werte voneinander ab, wirft der InquiryPaymentMediator einen Fehler.
  #
  # Damit soll das Problem umgangen werden, dass ein Nutzer auf einer gecachten
  # Seite den falschen/nicht-mehr-aktuellen Betrag zu bezahlen versucht.
  def start_paypal_payment_button(inquiry, modus:, amount:, &block)
    path = api_paypal_payment_start_path(inquiry_token: inquiry.token, modus: modus)
    opts = {
      class:  "btn btn-primary btn-block",
      data:   { disable_with: t(:wait) },
      params: { amount: format("%0.2f", amount.to_d) },
    }

    button_to path, opts, &block
  end

  def paypal_payment_status(payment) # rubocop:disable Metrics/CyclomaticComplexity
    raise ArgumentError, "expected PaypalPayment, got #{payment.class}" unless payment.is_a?(PaypalPayment)

    case payment.transaction_status
    when "created", "failed"
      t payment.transaction_status, scope: "payments.paypal.status.transaction"
    when "approved"
      case payment.sale_status
      when "pending", "denied"
        buf        = t(payment.sale_status, scope: "payments.paypal.status.sale")
        if (reason = payment.find_sale&.reason_code&.downcase)
          buf << h(": ") << t(reason, scope: "payments.paypal.pending_reason")
        end
        buf
      else
        t payment.sale_status, scope: "payments.paypal.status.sale"
      end
    end
  end

  private

  def charge_calculator(payment_gateway)
    currency, prices_include_cc_fee = if respond_to?(:inquiry)
      [inquiry&.currency, inquiry&.prices_include_cc_fee]
    else
      [Currency.current, Currency.current == Currency::USD]
    end

    PaypalHelper::ChargeCalculator.new payment_gateway,
      currency:              currency,
      prices_include_cc_fee: prices_include_cc_fee
  end
end
