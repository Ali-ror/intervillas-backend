module Billing::Template # rubocop:disable Style/ClassAndModuleChildren
  class Owner < Base
    attr_reader :recipient, :villa, :boat,
      :main_billing,
      :bank_account

    delegate :owner, :accounting, :agency_fee, :agency_commission, :payout, :currency,
      to: :billing

    delegate :start_date, :end_date, :period,
      to: :main_billing

    def initialize(owner_billing) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      unless owner_billing.is_a?(Billing::Owner)
        raise ArgumentError, "expected Billing::Owner instance, got #{owner_billing.class}"
      end

      super # setzt @date, @charges und @billing

      @recipient = billing.owner

      @villa_billing = billables.find { |b| b.is_a?(VillaBilling) }
      @villa         = @villa_billing.villa if @villa_billing

      @boat_billing = billables.find { |b| b.is_a?(BoatBilling) }
      @boat         = @boat_billing.boat if @boat_billing

      @main_billing = @villa_billing || @boat_billing

      @bank_account = {}
      {
        account_owner:  [owner.bank_account(billing.currency).account_owner,  ""],
        account_number: [owner.bank_account(billing.currency).account_number, "IBAN"],
        name:           [owner.bank_account(billing.currency).name, ""],
        address:        [owner.bank_account(billing.currency).address, ""],
        code:           [owner.bank_account(billing.currency).code, ""],
        routing_number: [owner.bank_account(billing.currency).routing_number, "RTN"],
      }.each do |key, (val, text)|
        @bank_account[key] = [escape(val), text] if val.present?
      end
    end

    def villa?
      !!villa
    end

    def boat?
      !!boat
    end

    def villa_address
      raise ArgumentError, "Villa not found" unless villa?

      @villa_address ||= format("%s, %s, %s %s %s", *%i[
        name
        street
        locality
        region
        postal_code
      ].map { |att| villa[att] })
    end

    def boat_name
      raise ArgumentError, "Boat not found" unless boat?

      @boat_name ||= boat.list_name
    end
  end
end
