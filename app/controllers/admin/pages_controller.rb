class Admin::PagesController < ApplicationController
  include Admin::ControllerExtensions

  before_action      :check_admin!,             except: :show
  skip_before_action :authenticate_user!,       only: :show
  skip_before_action :enforce_password_expiry!, only: :show
  skip_before_action :enforce_second_factor!,   only: :show

  expose(:pages)     { Page.includes(:translations, :domains, route: :translations).order(:id) }
  expose(:page_form) { PageForm.from_page page }

  expose :page do
    case action_name
    when "new", "create"
      pages.build(created_at: Time.current, updated_at: Time.current)
    when "edit", "update", "destroy"
      pages.find(params[:id])
    when "show"
      pg = pages.references(:domains, :route).find_by \
        domains: { id:   current_domain.id },
        routes:  { path: request.path[1..-1] }
      pg || pages.find(params[:id])
    end
  end

  # DEPRECATED: app/helpers/route_helper.rb (+ ggf. weitere) will gerne
  #             eine resouce haben
  expose(:resource) { page }

  layout :choose_layout

  def show
    @title = page.name
  end

  def create
    create_or_update :new, t("admin.pages.created")
  end

  def update
    create_or_update :edit, t("admin.pages.updated")
  end

  def destroy
    page.destroy
    redirect_to admin_pages_path, notice: t("admin.pages.destroyed")
  end

  private

  def noindex?
    params[:action] == "show" && page.noindex? && super
  end

  def create_or_update(on_failure, success_msg)
    if page_form.process(permitted_params)
      page_form.save
      redirect_to admin_pages_path, notice: success_msg
    else
      render on_failure
    end
  end

  def choose_layout
    params[:action] == "show" ? "application" : "admin_bootstrap"
  end

  def permitted_params
    params.require(:page).permit \
      :de_name,
      :en_name,
      :de_content,
      :en_content,
      :route_path,
      :route_name,
      :noindex,
      :published_at,
      :modified_at,
      domain_ids: []
  end
end
