# TODO: merge with LocaleExtractor?
# XXX: `module Localization` caused some conflicts
module LocalizationExtension
  extend ActiveSupport::Concern

  included do
    attr_reader :show_localization_select
    private :show_localization_select
    helper_method :show_localization_select?

    helper_method :build_host_for_locale
  end

  private

  def show_localization_select?
    show_localization_select
  end

  def show_localization_select!
    @show_localization_select = true
  end

  def build_host_for_locale(locale)
    [
      (locale.to_s == "de" ? "www" : "en"),
      ("staging" if Rails.env.staging?),
      ("local" if Rails.env.development?),
      normalized_request_domain,
    ].compact.join(".")
  end

  if Rails.env.test? || Rails.env.development?
    # Egde case handling for dev/test: localhost is technically a TLD, so
    # the apex domain for en.local.localhost is local.localhost. We don't
    # want to generate www.local.local.localhost though, so we drop
    # everything in front of .localhost.
    def normalized_request_domain
      domain = request.domain
      domain.ends_with?(".localhost") ? "localhost" : domain
    end
  else
    def normalized_request_domain
      request.domain
    end
  end
end
