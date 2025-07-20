module Inquiry::Clearing
  extend ActiveSupport::Concern

  included do
    has_many :clearing_items, dependent: :delete_all
    has_many :generic_clearing_items, -> { where boat_id: nil, villa_id: nil },
      class_name: "ClearingItem"

    accepts_nested_attributes_for :clearing_items, allow_destroy: true

    before_create :set_prices_include_cc_fee
  end

  def clearing(reload: false)
    @clearing = nil if reload

    prepare_boat_inquiry if villa.present? && villa.boat_inclusive? && boat_inquiry.nil?

    @clearing ||= ::Clearing.new(
      rentable_inquiries.map(&:clearing),
      generic_clearing_items,
    )
  end

  def prices_include_cc_fee
    super && !for_corporate?
  end

  def set_prices_include_cc_fee
    self.prices_include_cc_fee = currency == Currency::USD && !external
  end
end
