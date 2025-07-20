class Admin::HighSeasonsController < ApplicationController
  include Admin::ControllerExtensions
  layout "admin_bootstrap"

  expose :high_seasons do
    scope = HighSeason.includes(:villas).order(starts_on: :asc)

    if params[:historic] == "1"
      scope.where("ends_on < ?", Date.current)
    else
      scope.where("ends_on >= ?", Date.current)
    end
  end

  expose :high_season do
    if %w[new create].include? action_name
      HighSeason.new
    else
      HighSeason.find(params[:id])
    end
  end

  expose(:villas) { Villa.active.order(:name) }

  def new
  end

  def create
    save { render :new }
  end

  def update
    save { render :edit }
  end

  def destroy
    high_season.destroy
    flash[:info] = "Hochsaison gelöscht"
    redirect_to %i[admin high_seasons]
  end

  private

  def save
    high_season.attributes = high_season_params
    if high_season.save
      redirect_to %i[admin high_seasons]
    else
      yield
    end
  end

  def high_season_params
    params.require(:high_season).permit(:starts_on, :ends_on, :addition, villa_ids: [])
  end
end
