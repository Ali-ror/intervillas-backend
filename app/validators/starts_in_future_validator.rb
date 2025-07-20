#
# Für Datums-Attribute, deren Minimal-Wert "heute" nicht unterschreiten
# darf.
#
# Beispiele:
#
#     validates :vacation_begin, starts_in_future: true
#     validates :vacation_begin, starts_in_future: { in: 2.days }
#
# Note: absolute dates/timestamps are not supported (anymore), because
# they are once (!) evaluated at application boot time. Just provide
# an ActiveSupport::Duration
#
class StartsInFutureValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    min_date = min_date_from_options
    return if value && value >= min_date

    record.errors.add attribute, :future, after: I18n.l(min_date)
  end

  private

  def min_date_from_options
    duration = options.fetch(:in, 2.days)
    return duration.from_now.to_date if duration.is_a?(ActiveSupport::Duration)

    raise ArgumentError, "starts_in_future[:in] must be a ActiveSupport::Duration, got #{duration.class}"
  end
end
