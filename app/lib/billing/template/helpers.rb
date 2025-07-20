module Billing::Template # rubocop:disable Style/ClassAndModuleChildren
  module Helpers
    def l(*args, **opts)
      I18n.with_locale(locale) { I18n.l(*args, **opts).html_safe }
    end

    def t(*args, **opts)
      I18n.with_locale(locale) { I18n.t(*args, **opts) }
    end

    def format_currency(value, with_tex = true)
      no = number_with_precision(value.to_d, precision: 2, delimiter: "'".html_safe)
      return no unless with_tex

      "\\currency{#{no}}".html_safe # rubocop:disable Rails/OutputSafety
    end

    # translate Billing::Position#{subject, context}
    def tp(position)
      escape t "templates.billing.#{position.context}.#{position.subject}"
    end
  end
end
