json.daily_prices boat.daily_prices.to_a.reverse do |(days, price)|
  json.days    days
  json.per_day display_price(price)
  json.total   display_price(price * days)
end

json.discounts boat.holiday_discounts do |discount|
  json.extract! discount,
    :percent,
    :days_before,
    :days_after

  json.discount t(discount.description, scope: :discount)
  json.percent  discount.percent
end
