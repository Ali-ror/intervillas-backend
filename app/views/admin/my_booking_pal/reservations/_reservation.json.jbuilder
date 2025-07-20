json.extract! reservation,
  :id,
  :created_at,
  :reservation_id

json.product do
  if (pro = reservation.product).presence
    json.id   pro.id
    json.url  admin_my_booking_pal_product_path(pro.id)
  end
  json.name reservation.villa.admin_display_name
end

if (inquiry = reservation.inquiry.presence)
  json.inquiry do
    json.extract! inquiry,
      :number,
      :start_date,
      :end_date

    if inquiry.cancelled?
      json.cancelled true
      json.url edit_admin_cancellation_path(inquiry.id)
    else
      json.url edit_admin_booking_path(inquiry.id)
    end
  end
end

json.type reservation.type.demodulize.underscore

payload = reservation.payload
json.extract! payload,
  :total,
  :rent,
  :cleaning,
  :deposit

json.commission payload.total_commission
json.channel payload.channel_name
