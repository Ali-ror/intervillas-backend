module ApplicationHelper
  def localized_titles
    if I18n.locale.to_s == "de"
      %w[Herr Frau]
    else
      [%w[Mr Herr], %w[Mrs Frau]]
    end
  end

  def number_for_price_table(num)
    number_with_precision(num.to_d, precision: 2, delimiter: "'")
  end

  def controller_action
    [controller_name, action_name].join("#")
  end

  # change the default link renderer for will_paginate
  def will_paginate(collection, options = {})
    options[:renderer] ||= Bootstrap3LinkRenderer

    super collection, options
  end
end
