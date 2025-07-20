module VillaInquiry::Discounts
  extend ActiveSupport::Concern
  include HasDiscounts

  included do
    has_many :discounts, -> { where(inquiry_kind: :villa) }, through: :inquiry
  end

  def inquiry_kind
    :villa
  end

  def rentable
    villa
  end
end
