# == Schema Information
#
# Table name: cancellations
#
#  ack_downpayment     :boolean
#  booked_on           :datetime
#  cancelled_at        :datetime         not null
#  exchange_rate       :decimal(, )
#  pseudocardpan       :string
#  reason              :text
#  summary_on          :date
#  total_payment_cache :decimal(10, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  inquiry_id          :integer          primary key
#  travel_mail_id      :integer
#
# Indexes
#
#  index_cancellations_on_inquiry_id      (inquiry_id)
#  index_cancellations_on_travel_mail_id  (travel_mail_id)
#
# Foreign Keys
#
#  fk_cancellations_inquiry_id      (inquiry_id => inquiries.id)
#  fk_cancellations_travel_mail_id  (travel_mail_id => messages.id)
#

#
# Eine Kopie des Bookings. Änderungen an der bookings-Table müssen sich hier
# widerspiegeln, sonst klappt das Stornieren nicht mehr.
#
# Extra-Spalten gegenüber Booking:
# - cancelled_at
# - reason (Storno-Grund, siehe support#596)
#
# Fehlende Spalten ggü. Booking:
# - keine
#
class Cancellation < ApplicationRecord
  self.primary_key = :inquiry_id

  # muss vor dem include Bookings::Boat deklariert werden:
  belongs_to :inquiry, optional: true # optional, weil NULL erlaubt

  include Bookings::Presentation
  include Bookings::Boat
  include Bookings::Billings
  include Bookings::Payments

  # TODO: Relations und Delegates in Shared-Modul für Booking/Cancellation auslagern
  has_one :villa_inquiry, through: :inquiry
  has_one :villa, through: :villa_inquiry
  has_one :customer, through: :inquiry

  scope :villa, ->(villa_id) {
    joins(:villa_inquiry).where(villa_inquiries: { villa_id: }) if villa_id.present?
  }

  attr_accessor :skip_notification
  after_create_commit :trigger_messages,
    unless: :skip_notification

  delegate :adults, :children_under_6, :children_under_12, :start_date,
    :end_date, :date_range, :persons, :messages, :fee,
    to: :villa_inquiry

  delegate :comment, :payments, :clearing, :clearing_items, :currency,
    to: :inquiry

  strip_attributes only: %i[reason]

  def self.build_from_booking(booking)
    new.tap { |cancellation| cancellation.attributes = booking.attributes }
  end

  def cancelled?
    true
  end

  def state
    "cancelled"
  end

  def trigger_messages
    send_cancellation_messages if reason.present?
  end

  private

  def send_cancellation_messages
    MessageFactory.for(self).build_many.each do |m|
      m.text = reason
      m.save!
    end
  end
end
