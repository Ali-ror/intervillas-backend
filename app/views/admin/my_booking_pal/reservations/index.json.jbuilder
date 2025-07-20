page     = params.fetch("page", 1).to_i
per_page = 15

json.entries pagination do |r|
  json.partial! "reservation", reservation: r
  json.url admin_my_booking_pal_reservation_path(r)
end

json.pagination do
  json.total reservations.count
  json.per   per_page
  json.page  page
end
