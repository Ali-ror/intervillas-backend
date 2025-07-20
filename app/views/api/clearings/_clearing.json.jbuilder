common_ci_attributes = %i[id villa_id boat_id inquiry_id price category human_category _destroy]

json.rentable_clearings clearing.rentable_clearings do |rentable_clearing|
  json.rents rentable_clearing.rents do |clearing_item|
    json.call(clearing_item, *common_ci_attributes, :amount, :minimum_people, :start_date, :end_date, :time_units, :human_time_units, :total)

    json.normal_price clearing_item.normal_price if clearing_item.normal_price != clearing_item.price

    json.rentable clearing_item.rentable.admin_display_name

    json.period do
      json.start_date clearing_item.start_date
      json.end_date clearing_item.end_date
    end

    json.amount clearing_item.amount unless clearing_item.boat_id?
  end
end

json.other_clearing_items clearing.other_clearing_items.sort_by(&:order) do |clearing_item|
  raise "other_clearing_item must have amount 1" if clearing_item.amount != 1

  json.call(clearing_item, *common_ci_attributes, :note)
  json.normal_price clearing_item.normal_price
  json.rentable clearing_item.rentable.admin_display_name if clearing_item.rentable.present?
end

json.deposits clearing.deposits.sort_by(&:order) do |clearing_item|
  json.call(clearing_item, *common_ci_attributes)
  json.normal_price clearing_item.normal_price
  json.rentable clearing_item.rentable.admin_display_name if clearing_item.rentable.present?
end

json.call(clearing, :total_rents, :total, :sub_total)
json.currency(@currency || inquiry.currency)
