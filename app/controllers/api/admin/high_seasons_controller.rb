class Api::Admin::HighSeasonsController < ApplicationController
  include Admin::ControllerExtensions
  before_action :check_admin!

  expose(:villa) { Villa.find params[:villa_id] }
  expose(:dates) { %i[start_date end_date].map { |name| params[name].presence }.compact }

  expose(:high_seasons) do
    scope = villa.high_seasons
    scope = scope.overlaps(*dates) if dates.size == 2
    scope
  end

  def show
    headers["Cache-Control"] = "no-store"
    # render jbuilder template
  end
end
