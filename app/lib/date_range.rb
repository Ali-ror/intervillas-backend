class DateRange
  delegate :to_set, to: :half_days

  def initialize(start, endd)
    if start.is_a? HalfDay
      @start_half_day = start
    else
      @start_datetime = start
    end

    if endd.is_a? HalfDay
      @end_half_day = endd
    else
      @end_datetime = endd
    end
  end

  def start_datetime
    @start_datetime ||= start_half_day.datetime
  end

  def end_datetime
    @end_datetime ||= end_half_day.datetime
  end

  def spans_multiple_years?
    start_datetime.year != end_datetime.year
  end

  def half_days
    start_half_day..end_half_day
  end

  # DANGER: This is a very expensive operation when the range spans
  # multiple years.
  delegate :count,
    to:     :half_days,
    prefix: true

  def half_days_not_in(start_date, end_date)
    to_set.subtract DateRange.new(
      HalfDay.ante(start_date),
      HalfDay.post(end_date),
    ).to_set
  end

  def start_half_day
    @start_half_day ||= HalfDay.new start_datetime
  end

  def end_half_day
    @end_half_day ||= HalfDay.new end_datetime
  end
end
