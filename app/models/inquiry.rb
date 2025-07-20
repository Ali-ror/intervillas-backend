# == Schema Information
#
# Table name: inquiries
#
#  id                    :integer          not null, primary key
#  admin_submitted       :boolean          default(FALSE), not null
#  cancelled_at          :datetime
#  comment               :text
#  currency              :string           default("EUR"), not null
#  discount              :decimal(8, 2)    default(0.0), not null
#  discount_note         :string
#  external              :boolean          default(FALSE), not null
#  handling_note         :string
#  other_booked          :boolean          default(FALSE), not null
#  prices_include_cc_fee :boolean          default(FALSE), not null
#  reminded_on           :date
#  token                 :string(50)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  customer_id           :integer
#
# Indexes
#
#  fk__inquiries_customer_id  (customer_id)
#  index_inquiries_on_token   (token) UNIQUE
#
# Foreign Keys
#
#  fk_inquiries_customer_id  (customer_id => customers.id)
#

class Inquiry < ApplicationRecord # rubocop:disable Metrics/ClassLength
  has_one :boat_inquiry
  has_one :boat, through: :boat_inquiry

  accepts_nested_attributes_for :boat_inquiry,
    update_only:   true,
    allow_destroy: true

  belongs_to :customer,
    optional: true # optional, weil NULL erlaubt
  accepts_nested_attributes_for :customer,
    update_only: true

  has_many :cables
  has_many :messages

  has_many :travelers
  accepts_nested_attributes_for :travelers,
    allow_destroy: true

  has_many :booking_pal_reservations,
    class_name: "MyBookingPal::Reservation::Base",
    dependent:  :nullify

  attr_accessor :skip_sync_traveler_dates
  before_update :sync_traveler_dates, unless: :skip_sync_traveler_dates

  scope :older_than, ->(older) { where inquiries: { created_at: (...older) } }
  scope :in_state, ->(state) {
    case state.to_s
    when "submitted"
      where(admin_submitted: false, other_booked: false)
    when "admin_submitted"
      where(admin_submitted: true)
    end
  }
  scope :search,     ->(q) { joins(:customer).where "first_name ILIKE :q OR last_name ILIKE :q", q: "%#{q.downcase}%" }
  scope :complete,   -> { where.not(customer_id: nil) }
  scope :incomplete, -> { where(customer_id: nil) }
  scope :not_booked, -> {
    joins("LEFT OUTER JOIN bookings ON inquiries.id = bookings.inquiry_id")
      .where(bookings: { inquiry_id: nil })
  }

  scope :currency, ->(currency) { where(currency:) }

  include Digineo::Token
  include Inquiry::CommonScopes
  include Inquiry::Clearing
  include Inquiry::Villas
  include Inquiry::Discounts
  include Inquiry::Communications
  include Inquiry::Presentation
  include Inquiry::Destroyable
  include Inquiry::Cancellable
  include Inquiry::Billings
  include Inquiry::Paypal
  include Inquiry::Reservation
  include Inquiry::Booking
  include Inquiry::External
  include Inquiry::Reviews
  include Inquiry::Payments

  delegate :boat_state, :boat_days,
    to: :boat_inquiry

  def self.new_from_controller(params)
    new(params.to_h).tap { |inq|
      inq.prepare_boat_inquiry if inq.villa_inquiry.villa.boat_inclusive?

      inq.boat_inquiry.skip_clearing_items  = true if inq.boat_inquiry.present?
      inq.villa_inquiry.skip_clearing_items = true
    }
  end

  # Returns the terminal (non-final) object for this inquiry. The concrete
  # type depends on the inquiry's state:
  #
  # - when booked, it returns the associated Booking
  # - when cancelled, it returns the associated Cancellation
  # - otherwise it returns nil
  #
  # The method name reflects the fact that a Booking is usually the last
  # state an inquiry is shunted into (like an end-of-line railway station,
  # a terminus), and rareley needs to be maneuvered into a Cancellation.
  # Also, terminus is easily grep'able.
  #
  # @return [Booking|Cancellation|nil]
  def terminus
    booking || cancellation
  end

  def timely?
    start_date >= 2.days.from_now.to_date
  end

  def sync_traveler_dates
    new_start_date           = travelers.min_by(&:start_date)&.start_date
    villa_inquiry.start_date = new_start_date if new_start_date

    new_end_date           = travelers.max_by(&:end_date)&.end_date
    villa_inquiry.end_date = new_end_date if new_end_date
  end

  def with_boat?
    boat_inquiry.present?
  end

  def with_villa?
    villa_inquiry.present?
  end

  def boat_optional?
    with_villa? && villa.boat_optional?
  end

  def boat_charged?
    with_boat? && boat_state.charged?
  end

  def rentable_inquiries
    @rentable_inquiries ||= [villa_inquiry, boat_inquiry].compact
  end

  def still_available?
    rentable_inquiries.all?(&:still_available?)
  end

  def reserved?
    rentable_inquiries.any?(&:reserved?)
  end

  def rentable
    villa || boat
  end

  def prepare_boat_inquiry(without_boat: false)
    opts        = boat_inquiry_dates
    opts[:boat] = (villa_inquiry.villa.inclusive_boat || villa_inquiry.villa.optional_boats.first) unless without_boat
    build_boat_inquiry opts
  end

  def update_boat_inquiry
    boat_inquiry.update boat_inquiry_dates
  end

  private

  def boat_inquiry_dates
    {
      start_date: start_date + 1.day,
      end_date:   end_date - 1.day,
    }
  end
end
