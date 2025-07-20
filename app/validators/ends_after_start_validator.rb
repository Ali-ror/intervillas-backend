class EndsAfterStartValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # ends_after_start
    if value.present? && record.start_date.present? && value < record.start_date
      record.errors.add(attribute, :after_start)
    end
  end
end

