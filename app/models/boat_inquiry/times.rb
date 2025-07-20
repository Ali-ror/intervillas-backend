module BoatInquiry::Times
  extend ActiveSupport::Concern

  include BoatDaysCalculator

  def days
    boat_days
  end
  alias_method :period, :days

  def dates
    (date_range).to_a
  end

  def date_range
    start_date..end_date
  end

end
