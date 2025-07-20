# == Schema Information
#
# Table name: settings
#
#  key        :string           not null, primary key
#  updated_at :datetime         not null
#  value      :string           not null
#

class Setting < ApplicationRecord
  serialize :value, SettingCoercer

  COERCABLES = [
    SettingCoercer::BigDecimal.new("exchange_rate_usd",    "1.282"),
    SettingCoercer::BigDecimal.new("cc_fee_usd",           "3.5"),
    SettingCoercer::BigDecimal.new("paypal_fees_relative", "3.4"),
    SettingCoercer::BigDecimal.new("paypal_fees_absolute", "0.35"),
    SettingCoercer::BigDecimal.new("bsp1_fees_relative",   "2.9"),
    SettingCoercer::BigDecimal.new("bsp1_fees_absolute",   "0.09"),
    SettingCoercer::BigDecimal.new("energy_price_eur",     "0.14"),
    SettingCoercer::BigDecimal.new("energy_price_usd",     "0.17"),
  ].each_with_object({}) do |coercable, mapping|
    mapping[coercable.name] = coercable

    define_singleton_method coercable.name do
      coercable.get
    end

    define_singleton_method "#{coercable.name}=" do |val|
      coercable.set val
    end

    coercable.get # save default unless it already exist
  end
end
