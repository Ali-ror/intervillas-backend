class InquiryPaymentMediator # rubocop:disable Metrics/ClassLength
  class Auth
    attr_accessor :id, :url

    def initialize(id = nil, url = nil)
      @id  = id
      @url = url
    end

    def valid?
      url.present?
    end
  end

  # extend Paypal SDK to add support for "application context" attribute
  class Payment < PayPal::SDK::REST::Payment
    class ApplicationContext < PayPal::SDK::REST::Base
      def self.load_members
        object_of :brand_name, String
        object_of :locale, String
        object_of :landing_page, String
        object_of :shipping_preference, String
        object_of :user_action, String
        object_of :payment_pattern, String

        # not used, but must be declared
        object_of :preferred_payment_source, PreferredPaymentSource
      end
    end

    # not used, but must be defined
    class PreferredPaymentSource < PayPal::SDK::REST::Base
      def self.load_members
        object_of :token, PreferredPaymentSourceToken
      end
    end

    # not used, but must be defined
    class PreferredPaymentSourceToken < PayPal::SDK::REST::Base
      def self.load_members
        object_of :id, String
        object_of :type, String
      end
    end

    def self.load_members
      super
      object_of :application_context, ApplicationContext
    end
  end

  Payment.load_members # must be done once, manually

  include Rails.application.routes.url_helpers
  delegate :default_url_options,
    to: "Rails.application.config.action_mailer"

  Error            = Class.new StandardError
  UnexpectedAmount = Class.new Error
  NothingToPay     = Class.new Error

  class UnexpectedError < Error
    def initialize(paypal_error)
      @paypal_error = paypal_error
      super paypal_error["name"]
    end
  end

  attr_reader :inquiry
  attr_accessor :modus

  delegate :reservation_or_booking, :token, :number, :customer, :currency,
    to: :inquiry
  delegate :payment_deadlines,
    to: :reservation_or_booking
  delegate :downpayment_deadline, :remainder_deadline,
    to: :payment_deadlines
  delegate :logger,
    to: :Rails

  def initialize(inquiry)
    @inquiry = inquiry
  end

  def authorize(modus:, expected_amount: nil)
    self.modus = modus.to_s

    # Die Beträge auf der Zahlungsseite können veraltet sein, weil der Kunde
    # eventuell die Seite länger offen hatte und die Buchung zwischenzeitlich
    # nochmal verändert wurde.
    raise UnexpectedAmount if !expected_amount.nil? && payment_gross_sum != expected_amount

    payment = Payment.new payment_hash
    unless payment.create
      logger.error format("[%s] %p", self.class.name, payment.error)
      return Auth.new # empty
    end

    store(payment)
    Auth.new(payment.id, payment.approval_url)
  end

  def execute(payment_id, payer_id)
    payment = Payment.find(payment_id)

    num_retries = 5
    begin
      if payment.execute(payer_id: payer_id)
        store(payment)
        return true
      end

      if payment.error.present?
        case payment.error["name"]
        when "PAYMENT_ALREADY_DONE", "INSTRUMENT_DECLINED"
          store(payment)
          true
        else
          raise UnexpectedError, payment.error
        end
      end
    rescue UnexpectedError
      retry if (num_retries -= 1) > 0
      raise
    end
  end

  def cancel(web_token)
    payment = PaypalPayment.find_by(inquiry_id: inquiry.id, web_token: web_token)
    payment&.destroy
  end

  def payment_hash
    # "intent" muss "sale" sein, und "transactions" darf nur ein Objekt
    # enthalten, sonst bricht PaypalPayment auseinander!
    raise NothingToPay if charge_calculator.net <= 0

    {
      intent:              "sale",
      payer:               {
        payment_method: "paypal",
      },
      application_context: application_context,
      redirect_urls:       {
        return_url: api_paypal_payment_complete_url(inquiry_token: token),
        cancel_url: api_paypal_payment_cancel_url(inquiry_token: token),
      },
      transactions:        [{
        reference_id: number,
        item_list:    {
          items: [{
            url:      confirmation_booking_url(token: token),
            name:     [number, I18n.t(modus, scope: "payments.scope")].join(" "),
            price:    payment_net_sum,
            quantity: 1,
            currency: currency,
          }],
        },
        amount:       {
          total:    payment_gross_sum,
          currency: currency,
          details:  {
            subtotal:     payment_net_sum,
            handling_fee: payment_charge,
          },
        },
      }],
    }
  end

  private

  def payment_net_sum
    format "%0.2f", charge_calculator.net.to_d
  end

  def payment_gross_sum
    format "%0.2f", charge_calculator.gross.to_d
  end

  def payment_charge
    format "%0.2f", charge_calculator.charge.to_d
  end

  def charge_calculator
    deadline = case modus
    when "downpayment" then downpayment_deadline
    when "remainder"   then remainder_deadline
    end

    calc = PaypalHelper::ChargeCalculator.new :paypal,
      currency:              inquiry.currency,
      prices_include_cc_fee: inquiry.prices_include_cc_fee

    calc.add deadline.due_balance
  end

  # Creates a PaypalPayment DB record.
  def store(payment)
    inquiry.create_or_update_paypal_payment!(payment)
  end

  def application_context
    {
      brand_name:          "Intervilla Corp.",
      locale:              (customer.locale == "de" ? "de_DE" : "en_US"),
      landing_page:        "Billing",
      shipping_preference: "NO_SHIPPING",
      user_action:         "commit", # "Pay Now",
      payment_pattern:     "CUSTOMER_PRESENT_ONETIME_PURCHASE",
    }
  end
end
