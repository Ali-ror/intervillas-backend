class SimpleDatePickerInput < FormtasticBootstrap::Inputs::StringInput
  class SimpleDatePickerTag < ::ActionView::Helpers::Tags::TextField
    def render
      options          = @options.stringify_keys
      options["value"] = date_value(options.fetch("value") { value_before_type_cast })
      add_default_name_and_id(options)

      content_tag("simple-date-picker", nil, options)
    end

    private

    def date_value(value)
      return value if value.is_a?(String)

      value&.strftime("%Y-%m-%d")
    end
  end

  def to_html
    bootstrap_wrapping do
      template    = builder.instance_variable_get(:@template)
      object_name = builder.instance_variable_get(:@object_name)

      SimpleDatePickerTag.new(
        object_name,
        method,
        template,
        input_html_options, # not form_control_input_html_options, we don't want .form-control
      ).render
    end
  end
end
