class Admin::UsersController < ApplicationController
  include Admin::ControllerExtensions

  before_action :check_admin!
  layout "admin_bootstrap"

  expose(:collection) { User.includes(:contacts).ordered }
  expose(:resource) do
    if %w[new create].include?(action_name)
      collection.build
    else
      collection.find params[:id]
    end
  end

  expose(:basic_user_form) { UserForms::Basic.from_user(resource) }
  expose(:password_reset_form) { UserForms::PasswordReset.from_user(resource) }
  expose(:merge_user_form) { UserForms::Merge.from_user(resource) }
  expose(:contacts_form) { UserForms::Contacts.from_user(resource) }

  expose(:current_user_form) do
    case params[:form]
    when "password_reset"
      password_reset_form
    when "merge"
      merge_user_form
    when "contacts"
      contacts_form
    else
      basic_user_form
    end
  end

  def update
    if current_user_form.process(user_params)
      current_user_form.save
      flash[:warning] = blank_password_warning if current_user_form.blank_password?
      redirect_to admin_users_path, notice: current_user_form.success_message
    else
      flash.now[:warning] = blank_password_warning if current_user_form.blank_password?
      render action: :edit, error: current_user_form.error_message
    end
  end

  def create
    if current_user_form.process(user_params)
      current_user_form.save
      redirect_to [:edit, :admin, resource],
        notice: current_user_form.success_message
    else
      render action: :new, error: current_user_form.error_message
    end
  end

  def edit
    flash.now[:warning] = blank_password_warning if resource.blank_password?
  end

  def signin
    # tracked fields nicht aktualisieren
    def resource.update_tracked_fields!(*args)
    end

    session[:admin] = current_user.id
    sign_out current_user
    sign_in :user, resource

    redirect_to :admin_root, notice: t(".impersonation_successful", email: current_user.email)
  end

  def destroy
    resource.destroy

    flash[:success] = "Benutzer gelöscht"

    redirect_to admin_users_path
  end

  private

  def user_params
    permitted_attributes = case params[:form]
    when "password_reset" then return {}
    when "merge"          then %i[victim_id]
    when "contacts"       then { contact_ids: [] }
    else                       %i[email access_level]
    end
    params.require(:user).permit(permitted_attributes)
  end

  def blank_password_warning
    format <<~TEXT.squish, resource.email
      Benutzer %s verfügt noch über kein Passwort.
      Benutzen Sie die "Passwort zurücksetzen"-Funktion,
      damit der Benutzer sein Passwort setzen kann.
    TEXT
  end
end
