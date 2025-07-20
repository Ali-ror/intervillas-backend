# == Schema Information
#
# Table name: boat_inquiries
#
#  boat_name  :string
#  boat_state :string           not null
#  end_date   :date             not null
#  start_date :date             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  boat_id    :integer          not null, primary key
#  inquiry_id :integer          not null, primary key
#
# Indexes
#
#  fk__boat_inquiries_boat_id                      (boat_id)
#  fk__boat_inquiries_inquiry_id                   (inquiry_id)
#  index_boat_inquiries_on_inquiry_id_and_boat_id  (inquiry_id,boat_id) UNIQUE
#
# Foreign Keys
#
#  fk_boat_inquiries_boat_id     (boat_id => boats.id)
#  fk_boat_inquiries_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => cascade
#

class BoatInquiry < ApplicationRecord
  # Anlieferung ist morgens, Abnahme abends,
  # d.h. Buchungen dürfen sich nicht überlappen
  CLASH_QUERY = "start_date <= :end_date and end_date >= :start_date".freeze

  include Inquirable
  include Reservable

  has_one :villa_inquiry,
    through: :inquiry

  has_one :villa,
    through: :villa_inquiry

  include BoatInquiry::Clearing
  include BoatInquiry::Times
  include BoatInquiry::Discounts
  include RentableInquiry::Availability

  delegate :booked?,
    to: :inquiry

  delegate :optional?, :owner, :inclusive?,
    to: :boat

  after_create :notify_contacts, if: :booked?
  after_update :notifiy_contacts_on_update, if: :booked?
  after_destroy :notifiy_contacts_on_destroy, if: :booked?
  after_destroy :remove_clearing_items_on_destroy

  attr_accessor :skip_notification

  def name
    boat.admin_display_name
  end

  def boat_state
    bs = super || (inclusive? ? "free" : "charged")
    ActiveSupport::StringInquirer.new(bs)
  end

  def still_available?
    availability = Availability.new(self)
    availability.still_available?
  end

  # Boot ist extern, wenn Eigentümer nicht dem Eigentümer
  # der mitgebuchten villa entspricht
  def boat_external?
    villa.present? && villa.owner != owner
  end

  def billing_rent
    root_clearing = inquiry.clearing
    # clearing enthält Clearing::Boat

    # 60:40-Verteilung, wenn das Boot inklusive ist, oder (Altlast) die Villa
    # mal "inklusive Boot" gebucht wurde
    if boat.inclusive? || boat_state.free?
      [
        root_clearing.total_rents,
        root_clearing.total_reversal.to_d,
        root_clearing.total_regular_house_discount.to_d,
      ].sum * 0.4
    else
      clearing.total_rents + clearing.total_reversal.to_d + clearing.total_discount.to_d
    end
  end

  def agency_commission
    boat_billing&.agency_commission || 0
  end

  # Handles two possible scenarios:
  #
  # 1. If #boat_id has changed, send a cancellation message to the owner and
  #    manager of the previous (old) boat, and send a booking message to the
  #    owner and manager of the current (new) boat.
  #
  #    This case also handles changing of boat + dates.
  #
  # 2. If the #boat_id didn't change, but #start_date and/or #end_date did, send
  #    a change-dates notification to the owner and manager of the current boat.
  def notifiy_contacts_on_update
    return if skip_notification

    if saved_change_to_boat_id?
      if (old_boat_id = saved_changes["boat_id"][0])
        old_boat = Boat.find(old_boat_id)
        notify_contacts(action: "cancel", boat: old_boat)
      end

      notify_contacts
    elsif saved_change_to_start_date? || saved_change_to_end_date?
      notify_contacts(action: "dates")
    end
  end

  def notifiy_contacts_on_destroy
    notify_contacts(action: "cancel")
  end

  private

  def remove_clearing_items_on_destroy
    inquiry.clearing_items.where(boat_id:).destroy_all
  end

  def notify_contacts(action: "book", boat: rentable)
    return if skip_notification

    name = boat.admin_display_name
    text = I18n.t(action, scope: "message_mailer.note_mail.text.boat", name:)

    boat.notify_contacts(inquiry:, text:, action:)
  end
end
