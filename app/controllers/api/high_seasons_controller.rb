#
# Endpunkt für den HighSeasonProvider für den DateRangePicker
#
class Api::HighSeasonsController < ApiController
  # GET /api/high_seasons(.json)
  def show
    render json: seasons.as_json(only: [:starts_on, :ends_on], methods: :villa_ids)
  end

private

  memoize :reference_date, private: true do
    Date.current # params[:date]?
  end

  memoize :seasons, private: true do
    HighSeason.after(reference_date).includes(:villas)
  end

end
