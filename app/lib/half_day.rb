class HalfDay
  include Comparable

  def self.ante(date)
    date.to_datetime.change hour: 8
  end

  def self.post(date)
    date.to_datetime.change hour: 16
  end

  delegate :hour, :hash,
    to: :datetime

  attr_reader :datetime

  def initialize(datetime)
    @datetime = datetime
  end

  def succ
    HalfDay.new(datetime + (hour == 8 ? 8 : 16).hours)
  end

  def <=>(other)
    datetime <=> other.datetime
  end

  def eql?(other)
    datetime.eql? other.datetime
  end
end
