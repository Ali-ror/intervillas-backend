# == Schema Information
#
# Table name: reservations
#
#  ack_downpayment :boolean          default(FALSE), not null
#  exchange_rate   :decimal(, )
#  pseudocardpan   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  inquiry_id      :bigint           primary key
#
# Indexes
#
#  index_reservations_on_inquiry_id  (inquiry_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (inquiry_id => inquiries.id)
#
class Reservation < ApplicationRecord
  self.primary_key = :inquiry_id
  belongs_to :inquiry

  scope :valid, -> { where("reservations.created_at >= ?", 30.minutes.ago) }

  delegate :currency, :number,
    to: :inquiry

  include Bookings::Payments
  include Bookings::Clearing
  include Bookings::Customer

  # Wandelt Reservierung in eine "echte" Buchung um.
  def book!
    # XXX: In manchen Fällen existiert bereits eine Buchung, was beim Erzeugen
    # einer neuen Buchung zu einer unique constraint violation führt.
    #
    # Dies ist schon mehrfach beim Eintragen einer Zahlung aufgefallen, siehe
    # support#693.
    #
    # Unklar ist, warum die Buchung schon existiert, bzw. warum beim Erzeugen
    # dieser Buchung die Reservation nicht gelöscht wurde...
    if inquiry.booking.blank?
      attrs = attributes.except(:created_at, :updated_at)
      Booking.create!(attrs).trigger_messages
    end

    destroy!
  end

  def booked_on
    created_at.to_date
  end

  def ack_downpayment
    false
  end
end
