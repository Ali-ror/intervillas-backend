#
# Generiert einen Monatsplan
#
class Admin::GridController < ApplicationController
  include Admin::ControllerExtensions

  before_action :authorize_grid!

  layout "grid"

  memoize(:_year,       private: true) { params.fetch(:year).to_i }
  memoize(:_month,      private: true) { params.fetch(:month).to_i }
  memoize(:_start_date, private: true) { params.fetch(:start_date, Date.current).to_date }
  memoize(:_end_date,   private: true) { params.fetch(:end_date, _start_date - 1.month).to_date }

  expose :start_date do
    grid? ? Date.new(_year, _month, 1) : [_start_date, _end_date].min
  end

  expose :end_date do
    grid? ? start_date.end_of_month : [_end_date, _start_date].max
  end

  expose(:villas)    { current_user.villas.active }
  expose(:boats)     { current_user.boats.active.visible }
  expose(:old_boats) { current_user.boats.hidden }

  expose :grids do
    grid = Grid::Collection.new start_date, end_date

    {
      villas:    grid.villas(villas),
      boats:     grid.boats(boats),
      old_boats: grid.boats(old_boats),
    }
  end

  private

  def authorize_grid!
    authorize! :grid, Booking
  end

  def grid?
    params[:variant] == "grid"
  end
end
