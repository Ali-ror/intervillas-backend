class MinimumLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # Mindestdauer prufen
    if record.nights < record.minimum_nights
      record.errors.add(attribute, :min_length, count: record.minimum_nights)
    end
  end
end
