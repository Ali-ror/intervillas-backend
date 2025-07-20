class DiscountDays
  def self.build(discountish, has_dates)
    date_range = (has_dates.start_date..has_dates.end_date)

    # HolidayDiscounts gehen über mehrere Jahre
    #
    # XXX: Enumerable#sum wird mit 0 initialisiert, wir wollen am Ende aber eine
    # DiscountDays-Instanz haben.
    discountish.date_ranges(date_range.begin.year).sum(new) { |discount_range|
      date_range.each_with_object(new) { |date, acc|
        acc.add(date) if discount_range.include?(date)
      }
    }
  end

  attr_accessor :days

  delegate :present?,
    to: :days

  def initialize
    self.days = Set.new
  end

  def add(date)
    days << date
  end

  # Die (Kalender-)Tage sind aufpreispflichtig, aber die Anzahl der Nächte dient
  # als Grundlage für den Mietpreis. Um zu verhindern, dass, bei einer Buchung
  # über 4 Nächte für 5 Tage Aufschlag gezahlt werden muss, wird die Anzahl der
  # aufschlagspflichtigen Tage hier den gebuchten Nächten angepasst.
  def number_of_applicable_time_units(unit)
    raise ArgumentError, "expected :days/:nights, got #{unit}" unless %i[days nights].include?(unit)

    return 0 if days.size < 2

    # es kann nur auf maximal booking.nights einen Rabatt/Aufschlag geben
    unit == :days ? days.size : days.size - 1
  end

  def +(other)
    self.days += other.days
    self
  end

  def range
    start_date..end_date
  end

  private

  def start_date
    days.min
  end

  def end_date
    days.max
  end
end
