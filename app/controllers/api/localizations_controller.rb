class Api::LocalizationsController < ApplicationController
  skip_before_action :set_currency, :set_locale

  def update
    {
      currency: (Rails.env.test? ? params[:currency] : nil).presence,
      locale:   params[:locale].presence,
    }.each do |key, value|
      cookie_name = "l10n-#{key}"

      if value
        cookies.permanent[cookie_name] = {
          value:,
          secure:    Rails.env.production?,
          same_site: :lax,
          domain:    :all,
        }
      else
        cookies.delete(cookie_name, domain: :all)
      end
    end

    render :json,
      json:   { url: redirect_target },
      status: :found
  end

  private

  def target_domain
    domain = build_host_for_locale(params["locale"])

    case request.protocol
    when "http://"
      domain << ":#{request.port}" unless request.port == 80
    when "https://"
      domain << ":#{request.port}" unless request.port == 443
    end

    domain
  end

  def redirect_target
    path = params["path"].presence || "/"
    request.protocol + File.join(target_domain, path)
  end
end
