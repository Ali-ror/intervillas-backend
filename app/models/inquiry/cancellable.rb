module Inquiry::Cancellable
  extend ActiveSupport::Concern

  NotCancellable = Class.new StandardError

  included do
    scope :cancelled,     -> { where.not(cancelled_at: nil) }
    scope :not_cancelled, -> { where(cancelled_at: nil) }

    has_one :cancellation
  end

  def cancelable?
    !cancelled_at?
  end

  def cancelled?
    cancelled_at?
  end

  # use `force: true` only in console
  def cancel!(timestamp = Time.current, reason: nil)
    raise NotCancellable, I18n.t("activerecord.errors.messages.already_cancelled") if cancelled?

    self.class.transaction do
      Cancellation.build_from_booking(booking).tap { |cancellation|
        cancellation.cancelled_at = timestamp
        cancellation.reason       = reason
      }.save!

      booking.destroy!

      update cancelled_at: timestamp, token: nil
    end
  end

  # Undoes a cancellation. It restores the booking, but does not restore
  # supplementary elements (like the booking's billing records).
  #
  # Warning: This will re-occupy villas and boats. This might create
  # double-bookings, because we're (deliberately) don't check for
  # other bookings/blockings which might have already occupied the
  # villa/boat since this inquiry was cancelled.
  def uncancel!
    raise ArgumentError, "nicht storniert" unless cancelled?

    b            = ::Booking.new
    b.attributes = cancellation.attributes.except("cancelled_at", "total_payment_cache", "reason")

    self.class.transaction do
      b.save!
      cancellation.destroy!
      set_token
      update cancelled_at: nil
    end
  end
end
