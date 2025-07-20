info = ::MyBookingPal.client.info

json.urls do
  json.base        root_url
  json.async_push  info.fetch("asyncPush")
  json.reservation info.fetch("reservationLink")
end
