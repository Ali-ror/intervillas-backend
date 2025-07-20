class DatetimeSelectInput < FormtasticBootstrap::Inputs::DatetimeSelectInput
  FRAGMENT_CLASSES = {
    year:   "col-xs-2",
    month:  "col-xs-3",
    day:    "col-xs-2",
    hour:   "col-xs-offset-1 col-xs-2",
    minute: "col-xs-2",
    second: "col-xs-2"
  }.freeze

  def fragment_class(fragment)
    (options[:fragment_classes] || self.class::FRAGMENT_CLASSES)[fragment.to_sym]
  end
end
