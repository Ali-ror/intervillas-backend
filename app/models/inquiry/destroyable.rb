module Inquiry::Destroyable
  extend ActiveSupport::Concern

  included do
    before_destroy :destroyable?
  end

  def destroyable?
    indestructable_reasons.empty?
  end

  def indestructable_reasons
    @indestructable_reasons ||= begin
      reasons = []
      reasons << :cancelled if cancelled?
      if booked?
        reasons << :booked    if !booking.booked_on.nil?
        reasons << :payements if booking.payments.any?
      end
      reasons
    end
  end
end
