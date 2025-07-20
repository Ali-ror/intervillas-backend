module Grid
  class Event
    include Dateable

    # Event-Subjekt, muss auf #to_s reagieren
    attr_reader :content

    def initialize(content, start_date:, end_date:)
      @content = content

      # Daten sortieren
      @start_date, @end_date = minmax_dates(start_date, end_date)

      # keine initiale Datumsbeschränkung
      @restrict_start, @restrict_end = @start_date, @end_date
    end

    def start_datetime
      start_date
    end

    def end_datetime
      end_date
    end

    # Anzahl der halben Tage
    #
    def half_days
      half_days_count # -> DateRange
    end

    def full_days
      # 11 half days == 5 full days
      half_days / 2
    end

    # Beginn des Events. Identisch mit dem Wert, dem #new übergeben wurde, es
    # sei denn, #restrict! hat den Anfrangsbereich beschränkt (dann gilt das
    # Maximum aus Konstruktor- und #restrict!-Parameter)
    def start_date
      @restrict_start
    end

    # Ende des Events. Identisch mit dem Wert, dem #new übergeben wurde, es sei
    # denn, #restrict! hat den Endbereich beschränkt (dann gilt das Minimum aus
    # Konstruktor- und #restrict!-Parameter)
    def end_date
      @restrict_end
    end

    def start_incl?
      start_date < start_date.midday
    end

    def end_incl?
      end_date > end_date.midday
    end

    def single?
      start_date.to_date == end_date.to_date
    end

    def restrict(sdate, edate)
      dup.restrict!(sdate, edate)
    end

    def restrict!(sdate, edate)
      rstart, rend = minmax_dates(sdate || @start_date, edate || @end_date)

      @restrict_start = rstart > @start_date ? rstart : @start_date
      @restrict_end   = rend   < @end_date   ? rend   : @end_date
      @date_range = nil
      self
    end

    def unrestrict!
      restrict! nil, nil
    end

    def <=>(other)
      unless self.class === other
        raise ArgumentError,
          "comparison of #{self.class} with #{other.class} failed"
      end
      start_date <=> other.start_date
    end

    def overlaps_with?(other)
      unless self.class === other
        raise ArgumentError, "expected #{self.class} instance"
      end
      overlaps?(other.start_date, other.end_date)
    end

    # angelehnt an http://makandracards.com/makandra/984
    def overlaps?(sdate, edate)
      start_date <= edate && end_date >= sdate
    end

    def minmax_dates(*list)
      list.map(&:to_datetime).minmax
    end
  end
end
