module BookingHelper
  def boat_date_range_picker_data(boat_inquiry)
    {
      min:   (boat_inquiry.inquiry.start_date.to_datetime + 1.day).change(hour: 8).iso8601,
      max:   (boat_inquiry.inquiry.end_date.to_datetime - 1.day).change(hour: 16).iso8601,
      start: boat_inquiry.start_date,
      end:   boat_inquiry.end_date,
    }
  end

  def reservation_conflict?(inquiry)
    inquiry.rentable_inquiries.any? do |ri|
      # noinspection RubyArgCount
      Availability.new(ri).conflicting_reservations.present?
    end
  end

  def book_button_label(inquiry)
    if inquiry.immediate_payment_required?(current_user)
      t("bookings.edit.continue")
    else
      t("bookings.edit.jetzt_buchen")
    end
  end
end
