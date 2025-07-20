# Methoden, die bei Objekten sinnvoll sind, die auf start_date und end_date
# antworten
#
# Abhängig von:
# - start_date
# - end_date
# - rentable_type
module Dateable
  extend ActiveSupport::Concern

  included do
    delegate :half_days_count, :half_days_not_in, :spans_multiple_years?,
      to: :date_range
  end

  def start_datetime
    hour = case rentable_type.to_s
    when "Villa" then 16
    when "Boat"  then 8
    end

    start_date.to_datetime.change(hour:)
  end

  def end_datetime
    hour = case rentable_type.to_s
    when "Villa" then 8
    when "Boat"  then 16
    end

    end_date.to_datetime.change(hour:)
  end

  def date_range
    @date_range ||= DateRange.new(start_datetime, end_datetime)
  end
end
