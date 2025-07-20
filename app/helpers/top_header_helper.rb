module TopHeaderHelper
  def link_to_locale(locale)
    host = build_host_for_locale(locale)

    link_class  = "active" if I18n.locale == locale
    link_params = _keep_params.merge(host: host, locale: locale.to_s)

    link_to link_params, class: link_class do
      fa :fw, :arrow_right, text: t(locale, scope: :locales)
    end
  end

  def link_to_currency(which, opts = {})
    data = (opts[:data] || {}).merge \
      toggle:    :tooltip,
      placement: :bottom,
      container: "#main-menu"

    title = t(which, scope: "shared.currencies.switch_to")
    opts.merge! \
      class: [*opts[:class], "currency", ("active" if current_currency == which)],
      title: title,
      data:  data

    link_params = _keep_params.merge(currency: which)
    link_to(link_params, opts) do
      fa(:fw, current_currency.downcase) +
        fa(:fw, :arrow_right, class: "switch-currency") +
        fa(:fw, which.downcase, class: "switch-currency") +
        tag.span(" #{title}", class: "visible-xs-inline") # leading space is important in BS3
    end
  end

  def current_phone_number_link
    href, text = if current_geoip_location&.switzerland?
      ["tel:+41435430542", "+41 (0) 43 543 05 42"]
    elsif current_geoip_location&.america?
      ["tel:+12392687053", "+1 (239) 268 7053"]
    else
      ["tel:+4988142123005", "+49 (0) 881 42 123 005"]
    end

    link_to href, class: "contact-nav-item" do
      fa(:fw, :phone_square) + tag.span(text)
    end
  end

  private

  def _keep_params(keep: %i[start_date end_date])
    keep.each_with_object({}) { |name, list|
      list[name] = params[name].presence
    }.compact
  end
end
