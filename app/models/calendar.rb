# == Schema Information
#
# Table name: calendars
#
#  id         :bigint           not null, primary key
#  name       :string
#  url        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  villa_id   :bigint
#
# Indexes
#
#  index_calendars_on_url       (url) UNIQUE
#  index_calendars_on_villa_id  (villa_id)
#
# Foreign Keys
#
#  fk_rails_...  (villa_id => villas.id)
#

class Calendar < ApplicationRecord
  belongs_to :villa
  has_many :blockings

  validates :url,
    presence:   true,
    uniqueness: true,
    url:        { public_suffic: true }

  def clash_email_name
    name.presence || URI.parse(url).host
  end
end
