module Ical
  Event = Struct.new(:uid, :start_date, :end_date, :comment, keyword_init: true) do
    def self.parse(data, source_url)
      Icalendar::Event.parse(data)
        .select { |event| event.dtstart && event.dtend }
        .map    { |event| build(event, source_url) }
    end

    def self.build(event, source_url)
      comment = [
        event.summary,
        event.description&.value,
      ].compact.join(" / ")

      uid   = event.uid.value.presence
      uid ||= "#{event.dtstamp.value_ical}@#{source_url}"

      new \
        uid:        uid,
        start_date: event.dtstart.to_date,
        end_date:   event.dtend.to_date,
        comment:    comment
    end
  end
end
