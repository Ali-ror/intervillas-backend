class MediaController < ApplicationController
  skip_forgery_protection
  skip_before_action :set_locale
  skip_before_action :set_formtastic_builder
  skip_before_action :set_currency

  def show
    render plain: "Not Found", status: :not_found
  end

  private

  # same as in ApplicationController, but avoiding User lookup
  def set_sentry_context
    Sentry.set_extras \
      params: params.to_unsafe_h,
      url:    request.url
  end
end
