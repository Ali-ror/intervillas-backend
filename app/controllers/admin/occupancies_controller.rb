class Admin::OccupanciesController < ApplicationController
  include Admin::ControllerExtensions

  layout "admin_bootstrap"

  expose(:rentables) { current_user.send(params[:type]).for_occupancies.order(order) }

  expose(:year) do
    params.require :year
  rescue ActionController::ParameterMissing
    # https://git.digineo.de/intervillas/support/-/issues/794#note_42677 ._.
    params.require(:month).split("-").first
  end

  expose :rentable, before: :show do
    rentables.find params[:id]
  end

  # @!method grid
  expose :grid, before: :calendar do
    Grid::Calendar.new(rentable, year)
  end

  expose :bookings do
    bookings = rentable.bookings
    bookings = bookings.in_year(params[:year]) if params[:year].present?
    bookings.paginate page: params.fetch(:page, 1), per_page: 30
  end

  helper_method :occupancies_path, :occupancies_calendar_path

  def calendar
    respond_to do |format|
      format.html do
        if grid.has_collisions?
          render "collisions"
        else

          render layout: "grid"
        end
      end

      format.csv do
        style = :manager_owner unless current_user.admin?
        render(csv: rentable.bookings.in_year(year), style:)
      end
    end
  end

  private

  def order
    params[:type] == "villas" ? :name : :id
  end

  def occupancies_path(rentable)
    case rentable
    when Villa
      occupancies_admin_villa_path(rentable)
    when Boat
      occupancies_admin_boat_path(rentable)
    else
      raise rentable.inspect
    end
  end

  def occupancies_calendar_path(rentable, *)
    case rentable
    when Villa
      occupancies_calendar_admin_villa_path(rentable, *)
    when Boat
      occupancies_calendar_admin_boat_path(rentable, *)
    else
      raise rentable.inspect
    end
  end
end
