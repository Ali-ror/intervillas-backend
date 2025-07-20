class ColumnCheckBoxesInput < FormtasticBootstrap::Inputs::CheckBoxesInput
  def checkbox_wrapping(&block)
    class_name = "checkbox col-md-3"
    class_name += " checkbox-inline" if options[:inline]
    template.content_tag :div, template.capture(&block).html_safe, class: class_name
  end

  def bootstrap_wrapping(&block)
    form_group_wrapping do
      label_html << template.content_tag(:div, class: "form-wrapper row") do
        input_content(&block) << hint_html(:block) << error_html(:block)
      end
    end
  end
end
