module Bookings::Status
  extend ActiveSupport::Concern

  BOOKED_FLAGS = %w[booked commission_received full_payment_received].freeze

  included do
    belongs_to :payment_view,
      class_name:  "Payment::View",
      foreign_key: :inquiry_id,
      optional:    true

    scope :booked, -> { in_state(BOOKED_FLAGS) }

    scope :in_state, ->(states) {
      states = states.split(",") if states.is_a?(String)
      joins(:payment_view).where(payments_view: { state: states })
    }

    scope :filter_states, ->(states) {
      states.empty? ? all : joins(:payment_view).where.not(payments_view: { state: states })
    }
  end

  # Der Status kann schon via find_by_sql (lib/balance.rb) vorgeladen sein.
  # In diesem Fall wollen wir keinen weiteren Query absetzen.
  def state
    return :external if inquiry.external

    @state ||= attributes.fetch("state") {
      payment_view.ack_downpayment? ? "commission_received" : payment_view.state
    }
  end

  # XXX: das müsste für ein Booking eigentlich immer wahr sein, oder nicht?
  def already_booked?
    BOOKED_FLAGS.include?(state)
  end

  alias booked? already_booked?

  module ClassMethods
    # XXX:  Ist es Zufall oder Absicht, dass das Array in der Methode identisch
    #       zu BOOKED_FLAGS ist?
    #
    #       (Aus BOOKED_FLAGS ist kürzlich "deposit_returned" verschwunden.)
    def states
      %w[booked commission_received full_payment_received].map { |state|
        [I18n.t(state, scope: :states), state]
      }
    end
  end
end
