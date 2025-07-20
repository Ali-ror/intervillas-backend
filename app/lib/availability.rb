class Availability < SimpleDelegator
  def rentable
    @rentable ||= case __getobj__
      when VillaInquiry, VillaInquiryForms::ForInquiry # Admin ist hier die Basis-Klasse
        villa
      when BoatInquiry, BoatInquiryForms::Base
        boat
      when BlockingForm, Blocking
        __getobj__.rentable
    end
  end

  def still_available?
    conflicting_bookings.empty? && conflicting_blockings.empty?
  end

  def reserved?
    conflicting_reservations.present?
  end

  def inquiry_class
    "#{rentable.class}Inquiry".constantize
  end

  def rentable_id_key
    rentable.model_name.singular + "_id"
  end

  def conflicting_reservations
    inquiry_class
      .clashes(start_date, end_date)
      .joins(:reservation)
      .merge(Reservation.valid)
      .where(rentable_id_key => rentable.id)
      .where.not(inquiry_id: respond_to?(:inquiry_id) ? inquiry_id : nil).map(&:reservation)
  end

  def conflicting_bookings
    inquiry_class
      .clashes(start_date, end_date)
      .joins(:booking, :inquiry)
      .where(inquiries: { cancelled_at: nil })
      .where(rentable_id_key => rentable.id)
      .where.not(inquiry_id: respond_to?(:inquiry_id) ? inquiry_id : nil)
  end

  def conflicting_blockings
    Blocking.clashes(start_date, end_date)
            .where(rentable_id_key => rentable.id)
            .where.not(id: (blocking? ? id : nil))
  end

  def blocking?
    __getobj__.is_a?(Blocking) || __getobj__.is_a?(BlockingForm)
  end
end
