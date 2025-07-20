# == Schema Information
#
# Table name: villa_billings
#
#  id                  :integer          not null, primary key
#  agency_fee          :decimal(8, 2)    default(15.0), not null
#  commission          :integer          not null
#  energy_price        :decimal(8, 2)
#  energy_pricing      :integer          default("usage"), not null
#  meter_reading_begin :decimal(8, 2)
#  meter_reading_end   :decimal(8, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  inquiry_id          :integer          not null
#  owner_id            :bigint           not null
#
# Indexes
#
#  fk__villa_billings_booking_id     (inquiry_id)
#  index_villa_billings_on_owner_id  (owner_id)
#
# Foreign Keys
#
#  fk_rails_...                  (owner_id => contacts.id)
#  fk_villa_billings_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => restrict
#

class VillaBilling < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Billable
  after_initialize :set_defaults,
    unless: :persisted?

  include Currency::Model
  currency_values :agency_fee, :energy_price

  enum :energy_pricing, {
    usage:    0, # Abrechnung nach Preis
    flat:     1, # Pauschalpreis
    included: 2, # Energiekosten in Miete enthalten
  }

  delegate :boat_inquiry,
    to: :inquiry

  delegate :start_date, :end_date, :days, :period, :billing_rent,
    to: :villa_inquiry

  strip_attributes only: %i[energy_price meter_reading_begin meter_reading_end]

  def positions
    @positions ||= [rent, pet_fee, early_checkin, late_checkout, cleaning, energy_unfeed].compact
  end

  def taxes
    @taxes ||= [total.taxes[tax_identifier(:sales)], total.taxes[:tourist]]
  end

  def rent
    @rent ||= begin
      value = billing_rent
      value = unfee(value) if unfee?
      Billing::Position.new(:rent, :villa, value, tax_identifier(:sales), :tourist)
    end
  end

  def cleaning
    @cleaning ||= begin
      value = villa_clearing.cleaning || 0
      value = unfee(value) if unfee?
      Billing::Position.new :cleaning, :villa, value, tax_identifier(:cleaning)
    end
  end

  def energy
    @energy ||= energy_position
  end

  def energy_unfeed
    @energy_unfeed ||= energy_position { |v| unfee? ? unfee(v) : v }
  end

  def pet_fee
    @pet_fee ||= if (value = villa_clearing.pet_fee.presence)
      Billing::Position.new(:pet_fee, :villa, value, tax_identifier(:sales), :tourist)
    end
  end

  def early_checkin
    @early_checkin ||= if (value = villa_clearing.early_checkin.presence)
      Billing::Position.new(:early_checkin, :villa, value, tax_identifier(:sales), :tourist)
    end
  end

  def late_checkout
    @late_checkout ||= if (value = villa_clearing.late_checkout.presence)
      Billing::Position.new(:late_checkout, :villa, value, tax_identifier(:sales), :tourist)
    end
  end

  def meter_reading
    @meter_reading ||= (meter_reading_end || 0) - (meter_reading_begin || 0)
  end

  def deposit
    @deposit ||= villa_clearing.total_deposit
  end

  def repeater_discount
    @repeater_discount ||= villa_clearing.repeater_discount
  end

  private

  def set_defaults # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    currency = inquiry&.currency

    self.agency_fee = if inquiry.present? && (agency_fee = rentable.owner&.agency_fee&.convert(currency))
      agency_fee
    else
      Currency::Value.euro(15.0).convert(currency || "EUR")
    end

    self.energy_price = if currency == Currency::EUR
      Currency::Value.new(::Setting.energy_price_eur, currency)
    else
      Currency::Value.new(::Setting.energy_price_usd, currency)
    end
  end

  def energy_position
    value = case energy_pricing
    when "usage"    then (meter_reading * (energy_price || 0)).ceil!
    when "flat"     then energy_price
    when "included" then Currency::Value.new(0, inquiry.currency)
    else raise ArgumentError, "unexpected energy_pricing: #{energy_pricing}"
    end

    value = yield(value) if block_given?

    Billing::Position.new(:energy, :villa, value, tax_identifier(:energy))
  end

  def clearing
    @clearing ||= inquiry.clearing
  end

  def villa_clearing
    @villa_clearing ||= clearing.for_rentable(:villa)
  end

  def unfee(amount)
    gcc.sub(amount).net
  end

  def unfee?
    inquiry.prices_include_cc_fee && !inquiry.external
  end

  def gcc
    @gcc ||= PaypalHelper::GenericChargeCalculator.new(::Setting.cc_fee_usd)
  end
end
