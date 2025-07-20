module Ical
  class EventBlocking
    attr_reader :blocking, :availability
    attr_accessor :event, :calendar_id, :scope

    delegate :still_available?,
      to: :availability

    def self.create_or_update(event, calendar_id:, scope:)
      new(event, calendar_id: calendar_id, scope: scope).create_or_update
    end

    def initialize(event, calendar_id:, scope:)
      self.event       = event
      self.calendar_id = calendar_id
      self.scope       = scope
    end

    def no_change?
      !blocking.saved_change_to_start_date? && !blocking.saved_change_to_end_date?
    end

    def conflicts
      availability.conflicting_bookings.map { [_1.booking, blocking] } +
        availability.conflicting_blockings.map { [_1, blocking] }
    end

    def create_or_update
      find_or_create
      blocking.update!(
        ical_uid:   event.uid,
        start_date: event.start_date,
        end_date:   event.end_date,
        comment:    event.comment,
      )
      self
    end

    private

    def find_or_create
      # scope enthält bereits die calendar_id
      uid       = { ical_uid: event.uid }
      dates     = { start_date: event.start_date, end_date: event.end_date }
      @blocking = scope.find_by(**uid) || scope.find_by(**dates) || scope.build(**uid, **dates)

      # noinspection RubyArgCount
      @availability = Availability.new(@blocking)
    end
  end
end
