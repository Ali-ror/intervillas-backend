module BillingForms
  class Base < ModelForm
    def self.model_name
      ActiveModel::Name.new self.class, nil, "Billing"
    end

    def self.from_billing(billing)
      new.tap { |form| form.billing = billing }
    end

    delegate :inquiry,
      to: :billing

    delegate :id, :to_param, :persisted?, :new_record?, :booking, :cancellation,
      to: :inquiry

    attr_accessor :boat, :villa

    # Setter in Subklasse überschreiben
    attr_reader :billing

    attribute :charges, [ChargesForm]

    attribute :commission, Integer
    validates :commission,
      presence:     true,
      numericality: { greater_than_or_equal_to: 0 }

    def type
      self.class.name.demodulize.underscore
    end

    def bookable
      inquiry.cancelled? ? cancellation : booking
    end

    def charges_attributes=(params)
      params.each do |_, data|
        charge = charges.find { |c| c.id.to_s == data["id"] }
        unless charge
          # gar nicht erst erzeugen, wenn es gleich wieder gelöscht wird
          next if data["_destroy"] == "1"

          charge = ChargesForm.from_charge(billing.charges.build)
          charges << charge
        end

        charge.attributes = data.except("id")
      end
    end

    def valid?
      super && charges.all?(&:valid?)
    end

    def save
      ActiveRecord::Base.transaction do
        attributes.except(:charges).each do |k, v|
          billing[k] = v
        end

        bookable.summary_on ||= Date.current.beginning_of_month
        charges.map(&:save).all? && billing.save && bookable.save
      end
    end
  end

  class Villa < Base
    delegate :villa_inquiry,
      to: :inquiry
    delegate :flat_energy_cost_calculation,
      to: :villa_inquiry

    attribute :agency_fee, Integer
    validates :agency_fee,
      presence:     true,
      numericality: { greater_than_or_equal_to: 0 }

    attribute :energy_pricing
    validates :energy_pricing,
      inclusion: { in: VillaBilling.energy_pricings.keys }

    attribute :energy_price, BigDecimal
    validates :energy_price,
      presence:     { if: ->(b) { %w[usage flat].include?(b.energy_pricing) } },
      numericality: { allow_nil: true, greater_than_or_equal_to: 0 }

    attribute :meter_reading_begin, BigDecimal
    validates :meter_reading_begin,
      presence:     { if: ->(b) { b.energy_pricing == "usage" } },
      numericality: { allow_nil: true, greater_than_or_equal_to: 0 }

    attribute :meter_reading_end, BigDecimal
    validates :meter_reading_end,
      presence:     { if: ->(b) { b.energy_pricing == "usage" } },
      numericality: { allow_nil: true, greater_than_or_equal_to: :meter_reading_begin }

    def billing=(billing)
      @billing        = billing
      self.villa      = billing.villa
      self.commission = billing.commission
      self.agency_fee = billing.agency_fee
      self.charges    = billing.charges.map { |c|
        ChargesForm.from_charge(c)
      }

      self.energy_pricing       = billing.energy_pricing
      self.energy_price         = billing.energy_price
      self.meter_reading_begin  = billing.meter_reading_begin
      self.meter_reading_end    = billing.meter_reading_end
    end

    def attributes=(attrs)
      super

      case energy_pricing
      # when "usage" # do nothing
      when "flat"
        self.meter_reading_begin = nil
        self.meter_reading_end   = nil
      when "included"
        self.energy_price        = nil
        self.meter_reading_begin = nil
        self.meter_reading_end   = nil
      end
    end

    # beim Speichern der Villa-Billing auch das Boat-Billing aktualisieren
    def save
      return false unless super
      return true  unless (bi = inquiry.boat_inquiry)

      bi.build_billing.tap { |bb|
        bb.commission ||= commission
      }.save
    end
  end

  class Boat < Base
    def billing=(billing)
      @billing         = billing
      self.boat        = billing.boat
      self.commission  = billing.commission
      self.charges     = billing.charges.map { |c|
        ChargesForm.from_charge(c)
      }
    end
  end
end
