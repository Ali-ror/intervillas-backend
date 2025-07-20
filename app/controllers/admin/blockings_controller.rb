class Admin::BlockingsController < ApplicationController
  include Admin::ControllerExtensions

  layout "admin_bootstrap"

  expose :blocking_form, before: :edit do
    BlockingForm.from_blocking find_or_build_blocking
  end

  expose :rentables do
    current_user.send(rentable_type.pluralize)
  end

  expose :blocking do
    find_blocking
  end

  expose :rentable_id_key do
    if params[:id].present?
      find_rentable_id_key blocking.attributes
    elsif params[:blocking].present?
      find_rentable_id_key(params[:blocking])
    else
      find_rentable_id_key(params)
    end
  end

  def edit
    render :new
  end

  def create
    blocking_form.attributes = blocking_params
    if blocking_form.valid?
      blocking_form.save

      redirect_to occupancies_path(blocking_form.rentable)
    else
      render :new
    end
  end

  alias update create

  def ignore
    blocking.ignore!

    redirect_to occupancies_path(blocking_form.rentable, month: blocking.start_date.strftime("%Y-%m"))
  end

  def destroy
    blocking = find_blocking
    rentable_id = blocking.send(rentable_id_key)
    blocking.destroy

    redirect_to occupancies_path(rentables.find(rentable_id))
  end

  private

  def blocking_params
    params.require(:blocking).permit(%i[ villa_id boat_id start_date end_date comment ])
  end

  def find_rentable_id_key(parameters)
    # kann sowohl mit ActionController::Parameters-Instanz als auch mit Hash aufgerufen werden
    parameters = parameters.permit(:boat_id, :villa_id).to_h if parameters.respond_to?(:permit)
    parameters.find do |key, value|
      %w[ boat_id villa_id ].include?(key) && value.present?
    end.first
  end

  def occupancies_path(rentable, *rest, **kw)
    case rentable
    when Villa
      occupancies_admin_villa_path(rentable, *rest, **kw)
    when Boat
      occupancies_admin_boat_path(rentable, *rest, **kw)
    else
      raise rentable.inspect
    end
  end

  def find_blocking
    current_user.blockings.find params[:id]
  end

  def find_or_build_blocking
    if params[:id].present?
      find_blocking
    else
      new_blocking
    end
  end

  def new_blocking
    if params[:blocking].present?
      Blocking.new
    else
      Blocking.new start_date: start_date,
                   end_date: end_date,
                   rentable_id_key => rentable_id
    end
  end

  def start_date
    params.require :start_date
  end

  def end_date
    params.require :end_date
  end

  def rentable_type
    rentable_id_key.split("_").first
  end

  def rentable_id
    # existenz der rentable_id verifizieren
    @rentable_id ||= rentables.find(params.require(rentable_id_key)).id
  end
end
