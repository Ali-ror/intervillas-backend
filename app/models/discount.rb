# == Schema Information
#
# Table name: discounts
#
#  inquiry_kind :string           not null, primary key
#  period       :daterange
#  subject      :string           not null, primary key
#  value        :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  inquiry_id   :integer          not null, primary key
#
# Indexes
#
#  fk__discounts_inquiry_id                                    (inquiry_id)
#  index_discounts_on_inquiry_id_and_inquiry_kind_and_subject  (inquiry_id,inquiry_kind,subject) UNIQUE
#
# Foreign Keys
#
#  fk_discounts_inquiry_id  (inquiry_id => inquiries.id)
#

class Discount < ApplicationRecord
  self.primary_key = %i[inquiry_id inquiry_kind subject]

  belongs_to :inquiry

  delegate :rentable, to: :rentable_inquiry

  def self.add_missing_ranges
    Discount.all.map { |d|
      next unless d.rentable_inquiry.present? && d.source_discount.present?

      [d, DiscountDays.build(d.source_discount, d.rentable_inquiry)]
    }.compact.each do |d, dd|
      d.update period: dd.range
    end
  end

  def rentable_inquiry
    "#{inquiry_kind.classify}Inquiry".constantize.find_by(inquiry_id:)
  end

  def source_discount
    case subject
    when "christmas"
      rentable.holiday_discounts.christmas.last
    when "easter"
      rentable.holiday_discounts.easter.last
    when "special"
      # unwahrscheinlich, dass die Daten noch existieren
      nil
    end
  end

  def type
    subject == "special" ? "discount" : "addition"
  end

  # adds the Discount's percentage to the given argument
  def absolutize(value)
    (value * self.value) / 100
  end

  def period=(value)
    if value.is_a?(Array) && value.size == 2
      super(value[0]..value[1])
    else
      super
    end
  end
end
