# == Schema Information
#
# Table name: tags
#
#  id          :integer          not null, primary key
#  amenity_ids :string           default([]), not null, is an Array
#  countable   :boolean          not null
#  description :string
#  filterable  :boolean          default(TRUE)
#  name        :string           not null
#  name_one    :string
#  name_other  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :integer          not null
#
# Indexes
#
#  fk__tags_category_id                (category_id)
#  index_tags_on_name                  (name)
#  index_tags_on_name_and_category_id  (name,category_id) UNIQUE
#
# Foreign Keys
#
#  fk_tags_category_id  (category_id => categories.id) ON DELETE => cascade
#
class Tag < ApplicationRecord
  # == Neues Tag anlegen:
  #  tag = Category.find_by(name: "highlights").tags.create name: "pet_friendly",
  #                                                  countable: false
  #  tag.translations.create locale: :de, name_other: "Haustierfreundlich", description: "Haustierfreundlich"
  #  tag.translations.create locale: :en, name_other: "Pet Friendly", description: "Pet Friendly"
  translates :name_one, :name_other, :description

  belongs_to :category
  has_many :taggings

  has_many :areas,
    through:     :taggings,
    as:          :taggables,
    source:      :taggable,
    source_type: "Area"

  has_many :villas,
    through:     :taggings,
    as:          :taggables,
    source:      :taggable,
    source_type: "Villa"

  validates :name,
    presence:   true,
    uniqueness: { scope: :category_id }

  validates :countable,
    inclusion: { in: [true, false] }

  def to_s(amount = 1)
    return name_other unless countable?

    if amount == 1
      name_one || name_other(count: 1)
    else
      name_other(count: amount)
    end
  end

  def amenity_ids=(val)
    val = (val || []).flat_map { _1&.split(",") }.compact_blank
    super
  end
end
