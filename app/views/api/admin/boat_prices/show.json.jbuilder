json.prices boat.prices.valid_now do |price|
  json.call price,
    :id,
    :subject,
    :currency,
    :value

  if price.subject == "daily"
    json.amount price.amount
  end
end

json.holiday_discounts boat.holiday_discounts do |discount|
  json.call discount,
    :id,
    :description,
    :percent,
    :days_before,
    :days_after
end

json.exchange_rate_usd Setting.exchange_rate_usd.to_f
json.minimum_days boat.minimum_days
