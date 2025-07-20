module HasDiscounts
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_discounts

    before_create :add_discounts, unless: :skip_discounts
    before_update :reset_discounts
  end

  def discount_for(subject)
    discounts.find_by(subject: subject.to_s)
  end

  def add_discount(discount)
    discount.inquiry_kind = inquiry_kind
    inquiry.discounts << discount
  end

  def clear_discounts!
    inquiry.discounts.where(inquiry_kind:).destroy_all
  end

  def add_discounts
    discount_finder.each { add_discount _1 }
  end

  # Wenn der Buchungszeitraum und/oder das Haus geändert wurde, müssen die
  # Discounts/Aufschläge neu berechnet werden.
  def reset_discounts
    return true unless update_discounts?

    logger.debug "resetting discounts"
    clear_discounts!
    add_discounts
  end

  def discount_finder
    DiscountFinder.new(rentable, start_date, end_date, created_at)
  end

  private

  def update_discounts?
    (respond_to?(:villa_id_changed?) && villa_id_changed?) ||
      (respond_to?(:boat_id_changed?) && boat_id_changed?)
  end
end
