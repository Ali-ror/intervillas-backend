class UiSelectInput < FormtasticBootstrap::Inputs::SelectInput
  def input_html_options
    opts = super.merge(placeholder: I18n.t("helpers.select.prompt"))

    opts[":clearable"] = "true" if include_blank != false || input_options[:multiple]
    opts[":multiple"]  = "true" if input_options[:multiple]

    opts
  end

  # @see FormtasticBootstrap::Inputs::SelectInput (definition), and
  # formtastic-bootstrap (for BS4 customization).
  def to_html
    bootstrap_wrapping do
      select_html
    end
  end

  def select_html
    blank_option = case include_blank
    when String then include_blank
    when true   then "—"
    when false  then false
    end

    options  = []
    options << [blank_option, nil] unless blank_option == false
    options += collection

    builder.template.tag.ui_select_input nil, **input_html_options.merge(
      ":value"   => object.send(input_name).to_json,
      ":options" => options.to_json,
    )
  end
end
