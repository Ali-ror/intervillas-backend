class Admin::SpecialsController < AdminController
  load_and_authorize_resource :special
  defaults resource_class: Special

  actions :index, :edit, :update, :new, :create, :destroy

  layout "admin_bootstrap"

  def update
    super do |success, failure|
      success.html { redirect_to collection_path }
      failure.html { render :edit, status: :unprocessable_entity }
    end
  end

  def create
    super do |success, failure|
      success.html { redirect_to collection_path }
      failure.html { render :new, status: :unprocessable_entity }
    end
  end

  private

  def special_params
    params.require(:special).permit(
      :description,
      :percent,
      :start_date,
      :end_date,
      villa_ids: [],
    )
  end

  def end_of_association_chain
    super.includes(:villas).order(start_date: :desc)
  end
end
