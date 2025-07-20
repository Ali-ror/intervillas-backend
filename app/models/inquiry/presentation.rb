module Inquiry::Presentation
  def number
    "IV-#{'E' if external}#{id}"
  end

  def state
    return :cancelled       if cancelled?
    return :external        if external
    return booking.state    if booking.present?
    return :other_booked    if other_booked
    return :admin_submitted if admin_submitted

    :submitted
  end

  def event_title
    "#{number} #{customer.name} #{I18n.t(state, scope: :states)}"
  end

  def to_event_hash(type = "villa")
    s = start_date
    e = end_date

    if (bi = boat_inquiry) && type.to_s.downcase == "boat"
      s = bi.start_date
      e = bi.end_date
    end

    {
      id:        id,
      villa_id:  villa.id,
      boat_id:   boat.try(:id),
      title:     event_title,
      allDay:    true,
      start:     s,
      end:       e,
      className: [state, recently_created? ? "fresh" : nil].compact.join(" "),
      blocked:   false,
      path:      path,
    }
  end

  def recently_created?
    created_at > 2.weeks.ago
  end

  def path
    if booking.present?
      url_helpers.edit_admin_booking_path(booking)
    else
      url_helpers.edit_admin_inquiry_path(self)
    end
  end

  def rentable_names
    @rentable_names ||= InquiryUnion
      .where(inquiry_id: id)
      .map(&:rentable)
      .map(&:display_name)
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end
end
