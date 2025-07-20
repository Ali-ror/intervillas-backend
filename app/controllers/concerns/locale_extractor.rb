module LocaleExtractor
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    # the app locale is determined by the domain and/or parameters
    I18n.locale     = current_domain.language_code || LocaleDomain.extract(request)
    params[:locale] = I18n.locale.to_s

    # however, the user may has already set another preference
    @preferred_locale = preferred_locale_from_cookies
    return if @preferred_locale

    # when the user did not present a preference, guess the locale from
    # Accept-Language header
    @preferred_locale = preferred_locale_from_accept_header
    show_localization_select! if @preferred_locale != I18n.locale.to_s
  end

  def preferred_locale_from_cookies
    cookies["l10n-locale"].presence
  end

  # Extract preferred value from Accept-Language header.
  #
  # If highest q-valued language is "*" this returns the current locale.
  #
  # See https://httpwg.org/specs/rfc7231.html#header.accept-language and
  # https://httpwg.org/specs/rfc7231.html#quality.values for details.
  def preferred_locale_from_accept_header
    accepted = request.headers["Accept-Language"].presence
    return if accepted.blank?

    weighted  = aggregate_languages_by_weight(accepted)
    preferred = weighted.max_by(&:second).first
    preferred == "*" ? I18n.locale.to_s : preferred
  end

  def aggregate_languages_by_weight(languages)
    # input has form:       en-US, en;q=0.7, de-DE;q=0.3
    # after normalization:  { en-US => 1.0, en => 0.7, de-DE => 0.3 }
    # drop dialects:        { en: [1.0, 0.7], de: [0.3] }
    # maxiumum values:      { en: 1.0, de: 0.3 }
    # preferred language:   en
    languages.split(",").each_with_object(Hash.new(0)) do |field, w|
      lang, qval = field.split(";", 2).map(&:strip)

      quality = if qval && (m = qval.downcase.match(/^q=([01]\.\d{1,3})/))
        m[1].to_f
      else
        1.0
      end

      lang,   = lang.split("-", 2) # drop dialect
      w[lang] = quality if quality > w[lang] # combine and select maximum
    end
  end
end
