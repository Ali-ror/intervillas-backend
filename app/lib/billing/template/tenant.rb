module Billing::Template
  class Tenant < Base
    attr_reader :recipient, :bank_account,
      :villa, :villa_billing,
      :boat, :boat_billing

    delegate :deposits, :total_deposit, :total_charges, :total, :currency,
      to: :billing

    delegate :meter_reading, :meter_reading_begin, :meter_reading_end,
      :energy_price, :energy_pricing,
      to: :@villa_billing

    def initialize(tenant_billing)
      raise ArgumentError, "expected Billing::Tenant instance" unless tenant_billing.is_a?(Billing::Tenant)

      super # setzt @date, @locale, @charges und @billing

      @recipient = billing.customer
      @locale    = recipient.locale

      @villa_billing = billables.find { |b| b.is_a? VillaBilling }
      @villa         = @villa_billing.villa if @villa_billing

      @boat_billing = billables.find { |b| b.is_a? BoatBilling }
      @boat         = @boat_billing.boat if @boat_billing

      @bank_account = {
        number: customer.bank_account_number,
        owner:  customer.bank_account_owner,
        code:   customer.bank_code,
        name:   customer.bank_name,
        swift:  customer.swift_bank_account?,
      }
    end

    # Auf welche Weise soll die Kaution erstattet werden?
    #
    # Muss nur zwischen Überweisung und Kreditkarte unterscheiden
    # (paypal gilt hier als Kreditkarte intervillas/support#518)
    #
    # @return [Symbol]
    def payment_method
      if %w[bsp1 paypal].include? billing.payment_method
        :credit_card
      else
        :transfer
      end
    end

    def villa?
      villa.present?
    end

    def boat?
      boat.present?
    end

    def villa_name
      raise ArgumentError, "Villa not found" unless villa?

      @villa_name ||= villa.name
    end

    def boat_name
      raise ArgumentError, "Boat not found" unless boat?

      @boat_name ||= boat.list_name
    end
  end
end
