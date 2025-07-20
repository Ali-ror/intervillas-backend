json.array! high_seasons do |hs|
  json.call hs, :id, :name

  # renaming *_on to *_date makes JS code easier
  json.start_date hs.starts_on
  json.end_date hs.ends_on

  if dates
    date_range = (dates[0].to_date..dates[1].to_date)
    json.overlap hs.days_in_range(date_range)
  else
    json.overlap 0
  end
end
