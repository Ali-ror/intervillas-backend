module BoatDaysCalculator
  extend ActiveSupport::Concern

  def enough_boat_days?
    minimum_booking_days = if villa_inquiry.present?
      [self.minimum_booking_days, villa_inquiry.days - 2].min
    else
      self.minimum_booking_days
    end

    boat_days >= minimum_booking_days
  end

  def minimum_booking_days
    boat.minimum_days
  end

  def boat_days
    return 0 if end_date.nil? || start_date.nil?

    d = (end_date - start_date).to_i + 1
    d
  end

  # Bootsbuchungen nicht am An- und Abreisetag möglich
  def boat_days_overlapping?(which)
    return false unless villa_inquiry.present?
    return false if [start_date, end_date].any?(&:nil?)

    case which
    when :start
      start_date <= villa_inquiry.start_date
    when :end
      end_date >= villa_inquiry.end_date
    end
  end
end
