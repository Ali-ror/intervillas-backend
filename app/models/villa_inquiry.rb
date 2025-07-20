# == Schema Information
#
# Table name: villa_inquiries
#
#  adults                  :integer
#  children_under_12       :integer
#  children_under_6        :integer
#  end_date                :date             not null
#  energy_cost_calculation :integer          default("defer"), not null
#  start_date              :date             not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  inquiry_id              :integer          not null, primary key
#  villa_id                :integer          not null, primary key
#
# Indexes
#
#  fk__villa_inquiries_inquiry_id                    (inquiry_id)
#  fk__villa_inquiries_villa_id                      (villa_id)
#  index_villa_inquiries_on_inquiry_id_and_villa_id  (inquiry_id,villa_id) UNIQUE
#
# Foreign Keys
#
#  fk_villa_inquiries_inquiry_id  (inquiry_id => inquiries.id) ON DELETE => cascade
#  fk_villa_inquiries_villa_id    (villa_id => villas.id)
#

class VillaInquiry < ApplicationRecord # rubocop:disable Metrics/ClassLength
  # Abreise ist morgens, Anreise Nachmittags,
  # d.h. Buchungen dürfen sich überlappen
  CLASH_QUERY = "start_date < :end_date and end_date > :start_date".freeze

  include Inquirable
  include Reservable
  include NightsCalculator
  include VillaInquiry::Discounts
  include VillaInquiry::Clearing
  include RentableInquiry::Availability
  include VillaInquiry::EnergyCost

  delegate :name,
    to:        :villa,
    prefix:    true,
    allow_nil: true

  delegate :boat_inquiry, :booked?,
    to: :inquiry

  has_many :travelers, # rubocop:disable Rails/InverseOf
    foreign_key: :inquiry_id,
    primary_key: :inquiry_id

  before_create :create_initial_travelers

  after_update :notify_contacts_on_update, if: :booked?
  after_save :update_boat_inquiry, if: :booked?

  attr_accessor :skip_notification

  # XXX: Can a VillaInquiry be created with booked==true? Presumably, these
  # are created with the Inquiry, and the Booking will be created later.
  #
  # TODO: Revisit this when MyBookingPal::ReservationsController is done.
  after_commit on: %i[create destroy], if: :booked? do
    villa.booking_pal_product&.update_remote_prices!
  end

  after_commit on: :update, if: :booked? do
    villa.booking_pal_product&.update_remote_prices! if saved_change_to_start_date? || saved_change_to_end_date?
  end

  def dates
    date_range.to_a
  end

  def date_range
    start_date..end_date
  end

  def create_initial_travelers
    return if travelers.present?

    %i[adults children_under_6 children_under_12].each do |category|
      self[category].to_i.times do
        travelers.build(
          start_date:,
          end_date:,
          price_category: category.to_s,
        )
      end
    end
  end

  def adults
    if travelers.present?
      travelers.select { |t| t.price_category == "adults" }.count
    else
      self[:adults]
    end
  end

  def children_under_6
    if travelers.present?
      travelers.select { |t| t.price_category == "children_under_6" }.count
    else
      self[:children_under_6]
    end
  end

  def children_under_12
    if travelers.present?
      travelers.select { |t| t.price_category == "children_under_12" }.count
    else
      self[:children_under_12]
    end
  end

  def persons
    if travelers.present?
      travelers.count
    else
      [adults, children_under_12, children_under_6].sum(0, &:to_i)
    end
  end

  def update_boat_inquiry
    return unless saved_change_to_start_date? || saved_change_to_end_date?
    return if boat_inquiry.nil?
    return unless boat_inquiry.boat_state.free?

    inquiry.update_boat_inquiry
    true
  end

  def billing_rent
    inquiry.clearing # has side effects, prepares boat_inquiry if necessary

    ptp = clearing.total_rents + clearing.total_reversal + clearing.total_regular_house_discount

    # 60:40-Verteilung, wenn das Boot inklusive ist, oder (Altlast) die Villa
    # mal "inklusive Boot" gebucht wurde
    fac = boat_inquiry.present? && (villa.boat_inclusive? || boat_inquiry.boat_state.free?) ? 0.6 : 1.0

    ptp * fac
  end

  def agency_commission
    billing&.agency_commission || 0
  end

  def notify_contacts_on_update
    return if skip_notification

    if saved_change_to_villa_id?
      old_villa = Villa.find saved_changes["villa_id"][0]

      {
        cancel: old_villa,
        book:   villa,
      }.each do |action, rentable|
        notify_contacts(action:, villa: rentable)
      end

    elsif saved_change_to_start_date? || saved_change_to_end_date?
      notify_contacts(action: "dates")
    end
  end

  private

  def notify_contacts(action: "book", villa: rentable)
    return if skip_notification

    name = villa.admin_display_name.sub(/^Villa /, "")
    text = I18n.t(action, scope: "message_mailer.note_mail.text.villa", name:)

    villa.notify_contacts(inquiry:, text:, action:)
  end
end
