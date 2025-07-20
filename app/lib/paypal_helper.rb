module PaypalHelper
  class GenericChargeCalculator
    attr_accessor :absolute, :relative

    def initialize(relative, absolute = 0)
      self.absolute = absolute
      self.relative = relative
    end

    def convert(in_value, currency)
      Currency::Value.convert(in_value, currency, ceil: false)
    end

    Values = Struct.new(:net, :gross) do
      def charge
        gross - net
      end
    end

    # Die Zinsen beziehen sich auf den Brutto-Wert der Transaktion
    # "Welcher Betrag muss angefordert werden, damit am Ende die gewünschte"
    # "Summe nach Abzug der Gebühren bei uns übrig bleibt."
    def add(net)
      gross = (net + absolute) / (1 - amount)
      Values.new net, gross
    end

    def sub(gross)
      net = (gross * (1 - amount)) - absolute
      Values.new net, gross
    end

    def amount
      relative / 100
    end
  end

  class ChargeCalculator < GenericChargeCalculator
    attr_reader :payment_gateway

    private :absolute=, :relative=

    def initialize(payment_gateway, currency:, prices_include_cc_fee:)
      @payment_gateway = payment_gateway

      abs = prices_include_cc_fee ? 0 : Setting.send("#{payment_gateway}_fees_absolute") # 0.09
      rel = prices_include_cc_fee ? 1 : Setting.send("#{payment_gateway}_fees_relative") # 1.5

      super rel, convert(abs, currency)
    end
  end
end
