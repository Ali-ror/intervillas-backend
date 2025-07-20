# encoding: UTF-8
# == Schema Information
#
# Table name: areas
#
#  beds_count  :integer          default(0), not null
#  category_id :integer          not null
#  created_at  :datetime         not null
#  id          :integer          not null, primary key
#  subtype     :string
#  updated_at  :datetime         not null
#  villa_id    :integer          not null
#
# Indexes
#
#  fk__areas_category_id                    (category_id)
#  fk__areas_villa_id                       (villa_id)
#  index_areas_on_category_id_and_villa_id  (category_id,villa_id)
#  index_areas_on_villa_id_and_category_id  (villa_id,category_id)
#
# Foreign Keys
#
#  fk_areas_category_id  (category_id => categories.id)
#  fk_areas_villa_id     (villa_id => villas.id)
#

class Area < ApplicationRecord
  include Digineo::CountableTags

  validates_presence_of :villa, :category

  belongs_to :villa
  belongs_to :category
end
