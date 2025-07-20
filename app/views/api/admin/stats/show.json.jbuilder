json.call(@comparison, :prev_year, :year)
json.months @comparison do |month|
  json.number month.number
  json.name I18n.t(:month_names, scope: "date")[month.number]
  json.inquiries month.fetch(:inquiries), :prev_year, :year, :change
  json.admin_inquiries month.fetch(:admin_inquiries), :prev_year, :year, :change
  json.bookings month.fetch(:bookings), :prev_year, :year, :change
  json.utilization month.fetch(:utilization), :prev_year, :year, :change
  json.people month.fetch(:people), :prev_year, :year, :change
  json.adults month.fetch(:adults), :prev_year, :year, :change
  json.children_under_6 month.fetch(:children_under_6), :prev_year, :year, :change
  json.children_under_12 month.fetch(:children_under_12), :prev_year, :year, :change
end
