# see https://github.com/evgenygarl/flag-icons-rails/blob/master/lib/flag-icons-rails/rails/helpers.rb
module FlagHelper
  # Helper to render flag icon as single HTML element
  #
  # @param [Symbol|String] country_code ISO 3166-1 alpha-2 country code, see:
  #   https://www.iso.org/obp/ui/#search
  # @param [true, false] squared Optional. It is used to determine if square or rectangular
  #   version of flag will be rendered, defaults to +false+
  # @param [Symbol|String] element Optional. HTML element to generate and apply classes to,
  #   defaults to +:span+
  # @param [Hash] html_options Optional. HTML options applied to rendered element, defaults to +{}+
  #
  # @return [String] +element+ with requested HTML options to display country flag
  def flag_icon(country_code, squared: false, element: :span, **html_options)
    html_options[:class] = flag_icon_content_class(country_code, squared, html_options[:class])

    content_tag(element, nil, html_options)
  end

  private

  def flag_icon_content_class(country_code, squared, custom_css_class)
    content_classes = [
      "fi",
      "fi-#{country_code}".downcase,
      (squared ? "fis" : ""),
      custom_css_class,
    ]

    content_classes.join(" ").squish
  end
end
