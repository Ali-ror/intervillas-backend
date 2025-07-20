# == Schema Information
#
# Table name: inquiry_union_view
#
#  end_date      :date
#  inquiry_id    :integer
#  rentable_id   :integer
#  rentable_type :string(5)
#  start_date    :date
#

#
# Basiert auf View auf Union-Select von VillaInquiry und BoatInquiry
#
class InquiryUnion < ApplicationRecord
  self.table_name = "inquiry_union_view"

  belongs_to :rentable, polymorphic: true
  belongs_to :inquiry

  scope :in_year, ->(year) {
    where 'start_date BETWEEN :sd AND :ed OR end_date BETWEEN :sd AND :ed',
      sd: Date.parse("01-01-#{year}"),
      ed: Date.parse("31-12-#{year}")
  }

end
