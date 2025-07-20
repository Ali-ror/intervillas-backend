class OccupancyExporter < SimpleDelegator
  def self.from(rentable)
    min_gap = if rentable.is_a?(Villa)
      NightsCalculator::ABSOLUTE_MINIMUM_DAYS
    elsif rentable.is_a?(Boat)
      rentable.minimum_days
    else
      raise ArgumentError, "expected Villa or Boat instance"
    end

    new rentable, min_gap: min_gap
  end

  attr_reader :min_gap

  def initialize(rentable, min_gap:)
    super(rentable)

    @min_gap = min_gap
  end

  def except_inquiry!(id)
    @except_inquiry = id
  end

  def admin_export
    to_dates occupied_dates
  end

  def public_export(limit: nil)
    to_dates occupied_dates(limit: limit).each_with_object([]) { |curr, dates|
      if dates.empty?
        dates.push curr
        next
      end

      if dates.last[1] + min_gap > curr[0]
        dates.last[1] = curr[1]
      else
        dates.push curr
      end
    }
  end

  private

  def occupied_dates(limit: nil)
    dates = blocked_dates(except_inquiry: @except_inquiry, external: true)
      .map { |b| b.dates_for(model_name.singular) }
      .sort_by(&:last)

    cap_to_limit(dates, *limit)
  end

  def cap_to_limit(dates, limit_start = nil, limit_end = nil)
    return dates if limit_start.nil? || limit_end.nil?

    dates.reject! { |s, e| e < limit_start || s > limit_end }
    return [] if dates.empty?

    add_start_cap(dates, limit_start)
    add_end_cap(dates, limit_end)
    dates
  end

  def add_start_cap(dates, limit)
    dates.unshift([limit - 3.days, limit]) if dates.sort_by(&:first).first[0] > limit
  end

  def add_end_cap(dates, limit)
    dates.push([limit, limit + 3.days]) if dates.last[1] < limit
  end

  def to_dates(collection)
    collection.map { |a, b|
      [a.to_date, b.to_date]
    }
  end
end
