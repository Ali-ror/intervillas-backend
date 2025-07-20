# == Schema Information
#
# Table name: fees
#
#  amount     :decimal(8, 2)    not null
#  created_at :datetime         not null
#  inquiry_id :integer          not null, primary key
#  subject    :string           not null, primary key
#  updated_at :datetime         not null
#
# Indexes
#
#  fk__fees_inquiry_id                   (inquiry_id)
#  index_fees_on_inquiry_id_and_subject  (inquiry_id,subject) UNIQUE
#
# Foreign Keys
#
#  fk_fees_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => cascade
#

class Fee < ApplicationRecord

  self.primary_key = :inquiry_id, :subject

  belongs_to :inquiry

end
