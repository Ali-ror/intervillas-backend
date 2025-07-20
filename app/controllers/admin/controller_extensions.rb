module Admin::ControllerExtensions
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :enforce_password_expiry!
    before_action :enforce_second_factor!

    rescue_from CanCan::AccessDenied do |exception|
      logger.debug { [exception.to_s, exception.subject, exception.action].join ";" }
      redirect_to user_root_url, alert: I18n.t("devise.failure.access_denied")
    end
  end

  def current_ability
    @current_ability ||= AdminAbility.new(current_user)
  end

  private

  # Im Admin-Bereich gelten Euro-Preise für Villen-Verwaltung oder
  # die Währung der Buchung
  def set_currency
    Currency.current = Currency::EUR
  end

  # is not used everywhere, hence no top-level before_action
  def check_admin!
    head :forbidden unless current_user.try :admin?
  end

  def enforce_password_expiry!
    return unless current_user.password_expired?

    store_location_for(:user, url_for)
    # no flash, is handled either after login, or via permanent banner
    redirect_to admin_edit_user_registration_path
  end

  def enforce_second_factor!
    return unless current_user.role_requires_otp? && !current_user.otp_required_for_login?

    store_location_for(:user, url_for)
    flash[:error] = t("admin.two_factor_settings.required")
    redirect_to edit_admin_two_factor_settings_path
  end
end
