module Admin
  module BookingHelper
    def calendar_blocking_data_attributes(blocking)
      {
        event_url:    api_admin_bookings_path(villa: blocking.villa_id, format: :json),
        to_highlight: blocking.id,
        goto_date:    blocking.start_date.strftime("%Y-%m"),
      }
    end

    def calendar_data_attributes(rentable)
      rentable_key = rentable.model_name.singular

      event_url = if can?(:read, Inquiry)
        api_admin_inquiries_path(rentable_key => rentable.id, format: :json)
      else
        api_admin_bookings_path(rentable_key => rentable.id, format: :json)
      end

      {
        event_url:              event_url,
        view_mode:              can?(:create, Blocking) ? "0" : "1",
        new_blocking_path:      new_admin_blocking_path,
        "#{rentable_key}_id" => rentable.id,
        goto_date:              params[:month].presence,
      }.compact
    end
  end
end
