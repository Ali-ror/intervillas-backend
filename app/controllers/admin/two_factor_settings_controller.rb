module Admin
  class TwoFactorSettingsController < ApplicationController
    include Admin::ControllerExtensions

    skip_before_action :enforce_second_factor!

    layout "admin_bootstrap"

    def edit
      # render template
    end

    def create
      current_user.prepare_otp!
      redirect_to edit_admin_two_factor_settings_path
    end

    def update
      session[:otp_backup_codes] = current_user.enable_otp!(params[:otp_attempt])
      flash[:notice]             = t("created", scope: "admin.two_factor_settings")
      redirect_to edit_admin_two_factor_settings_path
    rescue User::OTPNotPrepared
      flash[:danger] = t("not_prepared", scope: "admin.two_factor_settings")
      render "edit"
    rescue User::OTPInvalid
      flash[:danger] = t("invalid_otp", scope: "admin.two_factor_settings")
      render "edit"
    end

    def destroy
      current_user.disable_otp!(params[:otp_attempt])
      flash[:notice] = t("deactivated", scope: "admin.two_factor_settings")
      redirect_to edit_admin_two_factor_settings_path
    rescue User::OTPInvalid
      flash[:danger] = t("invalid_otp", scope: "admin.two_factor_settings")
      render "edit"
    end
  end
end
