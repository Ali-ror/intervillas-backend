Comma::HeaderExtractor.value_humanizer = ->(value, model_class) {
  if model_class.respond_to?(:human_attribute_name)
    model_class.human_attribute_name(value)
  else
    value.is_a?(String) ? value : value.to_s.humanize
  end
}
