module Grid
  class Cell < SimpleDelegator
    attr_reader :event, :span

    def self.empty(content, span)
      new content, span, empty: true
    end

    def self.blank(span)
      new "", span, blank: true
    end

    def self.event(event, overlap = false)
      new event, event.half_days_count, overlap: overlap
    end

    # noinspection RubyArgCount
    def initialize(event, span, empty: false, overlap: false, blank: false)
      if event.is_a?(Grid::Event)
        super event.content
        @event = event
      else
        super event
      end

      @span    = span
      @empty   = !!(empty || blank) # rubocop:disable Style/DoubleNegation
      @blank   = !!blank            # rubocop:disable Style/DoubleNegation
      @overlap = !!overlap          # rubocop is find with this double negation!?
    end

    def overlap!
      @overlap = true
    end

    def type
      @type ||= __getobj__.class.name.underscore
    end

    def empty?
      @empty
    end

    def blank?
      @blank
    end

    def overlap?
      @overlap
    end

    def css_classes
      return unless respond_to?(:inquiry)

      [
        state,
        ("double-booking" if overlap?),
        ("my-booking-pal" if booking_pal_reservations?),
      ].compact
    end

    def number
      if created_at > 2.weeks.ago
        "* #{super} *"
      else
        super
      end
    end

    private

    def state
      if inquiry.is_a? Inquiry
        if inquiry.external?
          "external"
        else
          "booked"
        end
      elsif inquiry.is_a? Blocking
        "blocked"
      else
        raise "undefined state"
      end
    end

    def booking_pal_reservations?
      inquiry.is_a?(Inquiry) && inquiry.booking_pal_reservations.any?
    end
  end
end
