module BoatInquiry::Discounts
  extend ActiveSupport::Concern
  include HasDiscounts

  included do
    has_many :discounts, -> { where(inquiry_kind: :boat) }, through: :inquiry

    before_destroy :destroy_discounts
  end

  def destroy_discounts
    discounts.each(&:destroy)
  end

  def inquiry_kind
    :boat
  end

  def rentable
    boat
  end
end
