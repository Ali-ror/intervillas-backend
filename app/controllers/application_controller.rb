class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  include Exposer
  include LocaleExtractor
  include LocalizationExtension
  include LocalizedRoutes
  include RequestDomain::ControllerExtension
  include CurrencyExtractor
  include CorporateHelper

  helper :all # include all helpers, all the time

  before_action :set_formtastic_builder
  before_action :set_sentry_context
  before_action :configure_devise_parameter_sanitizer, if: :devise_controller?

  expose(:current_year)  { Date.current.year }
  expose(:current_month) { Date.current.month }
  expose(:chat_delay)    { 5 }

  private

  helper_method def noindex?
    current_domain.interlink? && !current_domain.default?
  end

  def i18n_attributes(*attributes)
    attributes.map { |attribute|
      I18n.available_locales.map { |locale|
        [locale, attribute].join("_").to_sym
      }
    }.flatten
  end

  def set_formtastic_builder
    Formtastic::Helpers::FormHelper.builder = FormtasticBootstrap::FormBuilder
  end

  def set_sentry_context
    Sentry.set_user(id: current_user.id) if user_signed_in?
    Sentry.set_extras \
      params: params.to_unsafe_h,
      url:    request.url
  end

  helper_method def require_recaptcha?
    Rails.env.production?
  end

  def configure_devise_parameter_sanitizer
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
