module CurrencyExtractor
  extend ActiveSupport::Concern

  USD_COUNTRY_CODES = %w[US CA].freeze

  included do
    before_action :set_currency
    helper_method :current_currency, :currencies, :current_geoip_location
  end

  private

  def current_currency
    Currency.current
  end

  def set_currency
    Currency.current = find_currency

    cookies.permanent["l10n-currency"] = {
      value:     Currency.current,
      secure:    Rails.env.production?,
      same_site: :lax,
      domain:    :all,
    }
  end

  def find_currency
    return Currency::USD unless Rails.env.test?

    currency_from_params     ||
      currency_from_cookies  ||
      currency_from_location ||
      currency_from_locale   ||
      currencies.first
  end

  def currencies
    Currency::CURRENCIES
  end

  def currency_from_cookies
    check_currency cookies["l10n-currency"]
  end

  def currency_from_params
    check_currency params[:currency]
  end

  def currency_from_locale
    return unless I18n.locale.to_s == "en"

    show_localization_select!
    Currency::USD
  end

  def check_currency(curr)
    curr if curr.present? && currencies.include?(curr)
  end

  def currency_from_location
    return unless USD_COUNTRY_CODES.include?(current_geoip_location&.code)

    show_localization_select!
    Currency::USD
  end

  def current_geoip_location
    @current_geoip_location ||= GeoIpResolver.resolve(request.remote_ip)
  end
end
