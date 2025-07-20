# encoding: UTF-8
# == Schema Information
#
# Table name: descriptions
#
#  id          :integer          not null, primary key
#  key         :string           not null
#  text        :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  category_id :bigint
#  villa_id    :integer          not null
#
# Indexes
#
#  fk__descriptions_villa_id               (villa_id)
#  index_descriptions_on_category_id       (category_id)
#  index_descriptions_on_villa_id_and_key  (villa_id,key) UNIQUE
#
# Foreign Keys
#
#  fk_descriptions_villa_id  (villa_id => villas.id) ON DELETE => cascade
#  fk_rails_...              (category_id => categories.id)
#

class Description < ApplicationRecord
  translates :text
  include Digineo::I18n

  default_scope { includes(:translations) }

  belongs_to :villa, touch: true
  belongs_to :category

  validates :key,
    presence:   true,
    uniqueness: { scope: :villa_id }

  validates :villa_id, :category_id,
    presence: true

  delegate :blank?, to: :text

  def to_s
    text.to_s
  end

  class << self
    # Categories and Descriptions are quite thightly coupled
    def find_category(key)
      key = "highlights" if ["header", "teaser", "description"].include?(key.to_s)
      Category.find_by(name: key)
    end

    def available
      distinct.pluck(:key)
    end
  end
end
