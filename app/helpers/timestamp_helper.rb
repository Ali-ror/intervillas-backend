module TimestampHelper
  def timestamp(time, js_format = nil, ignore_blank: false, convert_with: :created_at)
    return if time.blank? && ignore_blank

    time = time.send(convert_with) if time.respond_to?(convert_with)

    content_tag :span, time.iso8601,
      class: :timestamp,
      data:  js_format ? { format: js_format } : {}
  end

  module HumanDuration
    MINUTE = 60
    HOUR   = 60 * MINUTE
    DAY    = 24 * HOUR
    YEAR   = 365 * DAY

    def self.humanize(val)
      y, dur = val.abs.round.divmod(YEAR)
      d, dur = dur.divmod(DAY)
      h, dur = dur.divmod(HOUR)
      m, s   = dur.divmod(MINUTE)

      [
        (format("%dy ", y) if y > 0),
        (format("%dd ", d) if d > 0),
        (format("%dh ", h) if h > 0),
        format("%02d:%02d", m, s),
      ].compact.join
    end
  end

  def number_to_human_duration(val)
    HumanDuration.humanize(val)
  end
end
