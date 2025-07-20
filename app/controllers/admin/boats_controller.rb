class Admin::BoatsController < ApplicationController
  include Admin::ControllerExtensions
  inherit_resources

  layout "admin_bootstrap"

  # führt zu inkorrekter Sortierung in Sidebar
  # load_and_authorize_resource :boat

  defaults resource_class: Boat
  actions :edit, :update, :new, :create

  expose(:boat)             { resource }
  expose(:boats)            { current_user.boats.reorder(:matriculation_number, :id) }
  expose(:unbookable_boats) { Boat.unbookable }

  def update
    update! do |success, failure|
      success.html do
        flash_success!
        redirect_to edit_admin_boat_path(resource)
      end
      failure.html do
        logger.debug { resource.errors.inspect }
        render :edit
      end
    end
  end

  def create
    create! do |success, failure|
      success.html do
        flash_success!
        redirect_to edit_admin_boat_path(resource)
      end
      failure.html do
        render :new
      end
    end
  end

  def destroy
    boat.hide!
    flash[:notice] = "Boot wurde ausgeblendet"
    redirect_to admin_boats_path
  end

  private

  def flash_success!
    flash[:notice] = "Boot '#{boat.list_name}' wurde erfolgreich gespeichert"
  end

  def boat_params
    params.require(:boat).permit([
      :external,
      :model,
      :url,
      :horse_power,
      :matriculation_number,
      :manager_id,
      :owner_id,
      :minimum_days,
      {
        optional_villa_ids: [],
        domain_ids:         [],
      },
    ] + i18n_attributes(:description))
  end
end
