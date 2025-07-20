def skip_on_xmas?(ex)
  return false unless ex.metadata[:skip_on_xmas]

  today = Date.current
  xmin  = "#{today.year}-12-25".to_date - 7.days
  xmax  = "#{today.year}-12-26".to_date + 14.days

  xmin <= Date.current && Date.current <= xmax
end

RSpec.configure do |config|
  config.around do |ex|
    ex.run unless skip_on_xmas?(ex)
  end
end
