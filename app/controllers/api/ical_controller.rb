class Api::IcalController < ApiController
  expose :rentable_class do
    case params[:type]
    when "villas" then Villa
    when "boats"  then Boat
    else raise ActiveRecord::RecordNotFound
    end
  end

  expose(:rentable) { rentable_class.find_by id: params[:id], ical_token: params[:token] }
  expose(:bookings) { rentable.blocked_dates(external: include_external?).sort_by(&:start_date) }

  expose :calendar_name do
    format "%<name>s-%<id>d_%<date>s.ics",
      name: rentable_class.name,
      id:   rentable.id,
      date: Date.current.strftime("%Y-%m-%d")
  end

  expose :calendar do
    Icalendar::Calendar.new.tap { |cal|
      cal.prodid = "-//IDN intervillas-florida.com"

      bookings.each do |curr|
        cal.event do |event|
          event.dtstart = curr.start_date
          event.dtend   = curr.end_date
          event.summary = curr.number
          event.uid     = generate_uid(curr.class, curr.id)
        end
      end
    }
  end

  def show
    send_data calendar.to_ical,
      filename:    calendar_name,
      type:        Mime::Type.lookup_by_extension(:ics),
      disposition: :inline
  end

  private

  def generate_uid(*elems)
    Digest::SHA256.hexdigest [*elems, Rails.application.secret_key_base].join("")
  end

  def include_external?
    !without_external?
  end

  def without_external?
    # on the param name:
    # - in the beginning, the API included all kinds of blockings (this caused
    #   issues with exporting and re-imporing iCal data)
    # - some time later, it should not include external ones (hence the name)
    # - now, it should include them by default, and optionally not (and the
    #   param name ought not to change)
    params[:include_external] == "0"
  end
end
