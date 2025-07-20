# == Schema Information
#
# Table name: taggings
#
#  id            :integer          not null, primary key
#  amount        :integer
#  taggable_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tag_id        :integer          not null
#  taggable_id   :integer          not null
#
# Indexes
#
#  fk__taggings_tag_id                                         (tag_id)
#  index_taggings_on_tag_id_and_taggable_type_and_taggable_id  (tag_id,taggable_type,taggable_id) UNIQUE
#  index_taggings_on_taggable_id_and_taggable_type             (taggable_id,taggable_type)
#
# Foreign Keys
#
#  fk_taggings_tag_id  (tag_id => tags.id)
#

class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true, touch: true

  validates :tag_id,
    uniqueness: { scope: %i[taggable_type taggable_id] }

  validates :taggable_type,
    presence: true

  validates :amount,
    numericality: { greater_than: 0 },
    allow_nil:    true # why!?

  class << self
    def orphans
      distinct.pluck(:taggable_type).index_with { |type|
        where(taggable_type: type).where.not(taggable_id: type.constantize.pluck(:id))
      }
    end
  end
end
