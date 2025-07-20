
class MinBoatLengthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !record.enough_boat_days?
      record.errors.add(attribute, :min_boat_length,
                        count: record.minimum_booking_days)
    end
  end
end

