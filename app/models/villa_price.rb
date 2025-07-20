# == Schema Information
#
# Table name: villa_prices
#
#  additional_adult  :decimal(6, 2)    default(0.0), not null
#  base_rate         :decimal(6, 2)    not null
#  children_under_12 :decimal(6, 2)
#  children_under_6  :decimal(6, 2)
#  cleaning          :decimal(6, 2)    not null
#  currency          :enum             default("EUR"), not null, primary key
#  deposit           :decimal(6, 2)    not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  villa_id          :bigint           primary key
#
# Indexes
#
#  villa_prices_pkey  (villa_id,currency) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (villa_id => villas.id) ON DELETE => cascade
#
class VillaPrice < ApplicationRecord
  self.primary_key = %i[villa_id currency]

  # attributes holding monetary values
  MONETARY_ATTRIBUTES = %i[
    base_rate
    additional_adult
    children_under_6
    children_under_12
    cleaning
    deposit
  ].freeze

  enum :currency, {
    EUR: Currency::EUR,
    USD: Currency::USD,
  }

  belongs_to :villa,
    touch: true

  validates :children_under_12, :children_under_6,
    conflicting_minimum_people: { unless: :weekly_pricing? }

  after_commit do
    if (pro = villa.booking_pal_product) && pro.foreign_id?
      pro.update_remote_prices!
      pro.update_remote_fees!
    end
  end

  def weekly_pricing?
    [additional_adult, children_under_6, children_under_12].all? { |price|
      price.nil? || price.zero?
    }
  end

  # Manche Häuser verfügen nicht über alle Preiskategories, da z.B. Kinder nicht
  # erwünscht sind, oder Kinder wie Erwachsene bepreist werden.
  def traveler_price_categories
    Set.new [
      "adults",
      ("children_under_6"  if children_under_6.present?),
      ("children_under_12" if children_under_12.present?),
    ].compact
  end

  def as_villa_editor_json
    as_json(
      methods: %i[id], # NOTE: compound primary keys are methods, not attributes
      only:    MONETARY_ATTRIBUTES + %i[currency updated_at],
    )
  end

  # Wraps a VillaPrice and overrides MONETARY_ATTRIBUTES to return a
  # Currency::Value.
  #
  # See also:
  # - VillaPrice#to_monetary for the instantiation
  # - Villa#villa_price for the actual usage
  class MonetaryWrapper < SimpleDelegator
    attr_reader :target_currency
    attr_reader(*VillaPrice::MONETARY_ATTRIBUTES)

    def initialize(villa_price, target_currency)
      super(villa_price)

      @target_currency = target_currency
    end

    VillaPrice::MONETARY_ATTRIBUTES.each do |attr|
      define_method(attr) do
        val = instance_variable_get "@#{attr}"
        return val if val

        val = currency_value super()
        instance_variable_set "@#{attr}", val
      end
    end

    def calculate_base_rate(occupancy:, category: :adults)
      case category.to_s
      when "adults"
        return base_rate if occupancy <= villa.minimum_people

        base_rate + ((occupancy - villa.minimum_people) * additional_adult)
      when "children_under_6"
        occupancy * children_under_6
      when "children_under_12"
        occupancy * children_under_12
      else
        raise ArgumentError, "invalid category: #{category}"
      end
    end

    # for debugging, since SimpleDelegator overrides #inspect and #pp
    def raw
      [
        :__getobj__,
        :target_currency,
        :currency,
        *VillaPrice::MONETARY_ATTRIBUTES,
      ].index_with do |attr|
        public_send(attr)
      end
    end

    private

    def currency_value(val)
      val = Currency::Value.new(val, currency)
      target_currency == currency ? val : val.convert(target_currency)
    end
  end

  def to_monetary(target_currency = currency)
    MonetaryWrapper.new(self, target_currency)
  end
end
