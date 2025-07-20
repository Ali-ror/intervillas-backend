class OverlappingValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.boat_days_overlapping?(options[:with])
      record.errors.add(attribute, error_message(attribute))
    end
  end

  def error_message(attribute)
    :"overlaps_with_#{attribute}"
  end
end
