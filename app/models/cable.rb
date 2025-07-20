# == Schema Information
#
# Table name: cables
#
#  contact_id :integer
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  inquiry_id :integer
#  text       :text             not null
#  updated_at :datetime         not null
#
# Indexes
#
#  fk__cables_contact_id       (contact_id)
#  index_cables_on_inquiry_id  (inquiry_id)
#
# Foreign Keys
#
#  fk_cables_contact_id  (contact_id => contacts.id) ON DELETE => cascade
#  fk_cables_inquiry_id  (inquiry_id => inquiries.id)
#

class Cable < ApplicationRecord
  belongs_to :contact, optional: true # optional, weil NULL erlaubt
  belongs_to :inquiry, optional: true # optional, weil NULL erlaubt

  validates :text,
    presence:     true,
    allow_blank:  false

  delegate :number,
    to:     :inquiry,
    prefix: true
end
