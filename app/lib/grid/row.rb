module Grid
  class Row
    include Enumerable
    include Memoizable

    attr_reader :title
    attr_reader :start_date
    attr_reader :end_date
    attr_reader :events

    def initialize(title, start_date, end_date)
      @title  = title
      @events = []

      s, e        = [start_date, end_date].minmax
      @start_date = s.to_datetime.beginning_of_day
      @end_date   = e.to_datetime.end_of_day
    end

    def <<(event)
      @events << event if strict_matches?(event)
      self
    end

    def add_rentable_inquiry(inquiry)
      return false unless matches?(inquiry)

      event = Event.new inquiry,
        start_date: inquiry.start_datetime,
        end_date:   inquiry.end_datetime
      event.restrict! start_date, end_date

      @events << event
      true
    end

    memoize :header do
      event = Event.new title,
        start_date: start_date.midday,
        end_date:   end_date.midday
      Cell.new(event, 1)
    end

    def each(&block)
      dates.each do |_, splitday|
        splitday.each(&block)
      end
    end

    # Gruppiert Events nach Tag (für Monats-Ansicht)
    def dates
      @dates ||= group_events start_date.to_date, end_date.to_date
    end

    # Gruppiert Events erst nach Monat und dann nach Tag (für Jahres-Ansicht)
    #
    # XXX:  Ausgelegt für Events __eines__ Rentables, wenn Events mehrerer Villen
    #       oder Boote aggregiert werden sollen, bricht das hier ganz fürchterlich
    #       auseinander ;-)
    def months
      @months ||= begin
        s, e = start_date, end_date
        list = {}
        while s <= e
          t = s >> 1 # shift 1 month
          list[s] = group_events(s.beginning_of_day, (t-1).end_of_day).values
          s = t
        end
        list
      end
    end

    def group_events(from, to)
      days = (from .. to).each_with_object({}) {|d, list|
        list[d] = SplitDay.new(d)
      }

      from = from.beginning_of_day
      to   = to.end_of_day

      # XXX: strukturell sehr ähnlich zu Grid::Event#half_days
      events.each do |event|
        next unless event.overlaps?(from, to)
        ev   = event.restrict(from, to)
        s, e = ev.start_date.to_date, ev.end_date.to_date

        if ev.start_incl?
          days[s].ante = ev
          days[s].post = false if s != e || ev.end_incl?
        else
          days[s].post = ev
        end

        # Sonderfall: bei eintägigen Events (am Monatsanfang oder -ende)
        # können wir den Rest ignorieren
        next if s == e

        (s+1 .. e-1).each do |d|
          days[d].ante = false
          days[d].post = false
        end

        days[e].ante = false
        days[e].post = false if ev.end_incl?
      end

      days
    end

    def empty?
      events.empty? || dates.values.all?(&:blank?)
    end

    def overlaps?(event)
      @events.any? {|e| e.overlaps_with?(event) }
    end

  private

    def matches?(event)
      (start_date - event.end_datetime) * (event.start_datetime - end_date) >= 0
    end

    def strict_matches?(event)
      Event === event &&
      event.start_date >= start_date &&
      event.end_date   <= end_date
    end

  end
end
