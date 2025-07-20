class Api::Admin::StatsController < ApplicationController
  include Admin::ControllerExtensions

  def show
    @comparison = VillaStatsComparison.query(villa, year)
  end

  private

  def villa
    Villa.find params[:villa_id]
  end

  def year
    params[:year].to_i
  end
end
