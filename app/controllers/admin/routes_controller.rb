class Admin::RoutesController < AdminController
  load_and_authorize_resource :route
  defaults resource_class: Route

  layout "admin_bootstrap"

  actions :index, :edit, :update

  def update
    update! do |success, failure|
      success.html { redirect_to action: :index }
      failure.html { render action: :edit }
    end
  end

  private

  def route_params
    params.require(:route).permit([:path] + i18n_attributes(:html_title, :meta_description, :h1))
  end

  def end_of_association_chain
    super.includes(:resource).order Arel.sql("resource_type is not null, resource_type, resource_id")
  end
end
