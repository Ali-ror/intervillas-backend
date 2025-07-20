json.array! blockings do |blocking|
  clashes = blocking.clashing_bookings_and_blockings.sort_by(&:start_date)
  next if clashes.empty?

  json.call blocking,
    :id,
    :number,
    :start_date,
    :end_date,
    :comment

  json.clashes clashes do |clash|
    json.call clash,
      :number,
      :start_date,
      :end_date

    json.url case clash
    when VillaInquiry, BoatInquiry
      url_for([:admin, clash.booking])
    else
      url_for([:admin, clash])
    end
  end
end
