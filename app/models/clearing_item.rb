# == Schema Information
#
# Table name: clearing_items
#
#  id             :bigint           not null, primary key
#  amount         :integer          default(1), not null
#  category       :string           not null
#  end_date       :date
#  minimum_people :integer
#  normal_price   :decimal(8, 2)
#  note           :string
#  price          :decimal(, )      not null
#  start_date     :date
#  total_cache    :decimal(, )      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  boat_id        :bigint
#  inquiry_id     :bigint           not null
#  villa_id       :bigint
#
# Indexes
#
#  index_clearing_items_on_boat_id     (boat_id)
#  index_clearing_items_on_inquiry_id  (inquiry_id)
#  index_clearing_items_on_villa_id    (villa_id)
#
# Foreign Keys
#
#  fk_rails_...  (boat_id => boats.id)
#  fk_rails_...  (inquiry_id => inquiries.id) ON DELETE => cascade
#  fk_rails_...  (villa_id => villas.id)
#

# Kosten-Positionen für die Buchung (Mietpreise, Reinigung, etc.)
class ClearingItem < ApplicationRecord
  InvalidPrice = Class.new(StandardError)

  attr_accessor :_destroy

  belongs_to :inquiry
  belongs_to :booking,
    optional:    true,
    foreign_key: :inquiry_id,
    primary_key: :inquiry_id

  belongs_to :villa_inquiry,
    optional:    true,
    foreign_key: :inquiry_id,
    primary_key: :inquiry_id

  belongs_to :villa, optional: true
  belongs_to :boat, optional: true

  before_save :update_total_cache!

  def rentable
    villa || boat
  end

  def time_units
    nights = (end_date - start_date).to_i
    return nights + 1 if boat_id?

    nights
  end

  def human_time_units
    units = if villa_id?
      I18n.t("js.price_table.nights", count: time_units)
    else
      I18n.t("js.price_table.days", count: time_units)
    end

    [time_units, units].join " "
  end

  def price
    Currency::Value.new(super, inquiry&.currency || Currency.current)
  end

  def price=(value)
    if value.respond_to? :value
      super value.value
    elsif value.is_a? Hash
      super value.with_indifferent_access[:value]
    else
      super
    end
  end

  def total
    raise InvalidPrice, "ungültige Summe" if price.value.nil?

    subtotal = price * amount
    if traveler_category? || boat_rent?
      subtotal * time_units
    else
      subtotal
    end
  end

  def human_category
    if minimum_people?
      I18n.t category, scope: "admin.inquiries.clearing.#{scope}", count: minimum_people
    else
      I18n.t category, scope: "admin.inquiries.clearing.#{scope}"
    end
  end

  def order
    return 1 if villa_id?
    return 2 if boat_id?

    3
  end

  private

  def scope
    return :villa if villa_id?
    return :boat  if boat_id?

    :generic
  end

  def boat_rent?
    boat_id.present? && category.include?("price")
  end

  # which categories count as "traveler"?
  TRAVELER_CATEGORIES = Set[
    "adults", # legacy
    "base_rate",
    "weekly_rate",
    "additional_adult",
    "children_under_6",
    "children_under_12",
  ].freeze

  def traveler_category?
    TRAVELER_CATEGORIES.any? { |cat| category.start_with?(cat) }
  end

  def update_total_cache!
    v                = total
    self.total_cache = v if total_cache.nil? || total_cache.round(3) != v.round(3)
  end
end
