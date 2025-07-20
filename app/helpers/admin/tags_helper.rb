module Admin::TagsHelper
  def tag_input_form_field(form, field, **options)
    options = {
      label:        false,
      input_html:   { id: "tag_#{form.object.id}_#{field}" },
      wrapper_html: { id: "tag_#{form.object.id}_#{field}_input" },
    }.merge(options)

    form.input field, options
  end
end
