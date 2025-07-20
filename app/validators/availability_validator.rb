class AvailabilityValidator < ActiveModel::EachValidator
  # Verfügbarkeit prüfen
  def validate_each(record, attribute, value)
    availability = Availability.new(record)
    if availability.rentable.present? && !availability.still_available?
      record.errors.add(:start_date, :already_booked)
      record.errors.add(:end_date,   :already_booked)

      Rails.logger.debug {
        sprintf "AvailabilityValidator: conflicting bookings: %p, blockings: %p",
          availability.conflicting_bookings,
          availability.conflicting_blockings
      }
    end
  end
end
