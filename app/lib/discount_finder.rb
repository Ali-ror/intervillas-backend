DiscountFinder = Struct.new(:rentable, :start_date, :end_date, :created_at) do
  include NightsCalculator
  include DigineoExposer::Memoizable

  delegate :each, to: :discounts

  def discounts
    collect! unless defined?(@discounts)
    @discounts
  end

  alias_method :to_a, :discounts

  memoize(:christmas_days) do
    holiday_discounts.christmas.discount_days(self)
  end

  memoize(:easter_days) do
    holiday_discounts.easter.discount_days(self)
  end

  memoize(:special) do
    rentable.find_special_for_booking(self) if rentable.respond_to?(:specials)
  end

  memoize(:special_days) do
    DiscountDays.build(special, self) if special.present?
  end

  memoize(:high_season) do
    # TODO: We need to track *all* high seasons, not just the first (support#810).
    #       Dropping the `.first` requires quite a few additional changes...
    rentable.high_seasons.older_than(created_at).overlaps(*dates).first if rentable.respond_to?(:high_seasons)
  end

  memoize(:high_season_days) do
    DiscountDays.build(high_season, self) if high_season.present?
  end

  private

  def dates
    [start_date, end_date]
  end

  def date_range
    start_date..end_date
  end

  def collect!
    @discounts = []
    unit       = rentable.is_a?(Villa) ? :nights : :days

    with_days(christmas_days, unit:) do
      add_discount :christmas,
        period: christmas_days.range,
        value:  holiday_discounts.christmas.sum(:percent)
    end

    with_days(easter_days, unit:) do
      add_discount :easter,
        period: easter_days.range,
        value:  holiday_discounts.easter.sum(:percent)
    end

    with_days(special_days, unit:) do
      add_discount "special",
        period: (special.start_date..special.end_date),
        value:  special.percent * -1
    end

    with_days(high_season_days, unit:) do
      add_discount "high_season",
        period: high_season.date_range,
        value:  high_season.addition
    end
  end

  def holiday_discounts
    @holiday_discounts ||= rentable.holiday_discounts.where("created_at <= ?", created_at)
  end

  def add_discount(subject, period:, value:)
    @discounts << Discount.new(subject:, period:, value:)
  end

  def with_days(discounts, unit:)
    return unless discounts.present?

    yield if discounts.number_of_applicable_time_units(unit) > 0
  end
end
