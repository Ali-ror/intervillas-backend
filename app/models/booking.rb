# == Schema Information
#
# Table name: bookings
#
#  ack_downpayment :boolean          default(FALSE), not null
#  booked_on       :datetime
#  exchange_rate   :decimal(, )      not null
#  pseudocardpan   :string
#  summary_on      :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  inquiry_id      :integer          not null, primary key
#  travel_mail_id  :integer
#
# Indexes
#
#  fk__bookings_inquiry_id       (inquiry_id)
#  fk__bookings_travel_mail_id   (travel_mail_id)
#  index_bookings_on_inquiry_id  (inquiry_id) UNIQUE
#
# Foreign Keys
#
#  fk_bookings_inquiry_id      (inquiry_id => inquiries.id) ON DELETE => cascade
#  fk_bookings_travel_mail_id  (travel_mail_id => messages.id) ON DELETE => cascade
#

class Booking < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Inquiry::CommonScopes
  include Bookings::Communication
  include Bookings::Csv
  include Bookings::Presentation
  include Bookings::Billings # for tenants and owners
  include Bookings::Clearing
  include Bookings::Status

  self.primary_key = :inquiry_id

  belongs_to :inquiry
  include Bookings::Boat
  include Bookings::Payments
  include Bookings::Customer
  include Bookings::External

  # Villa
  has_one :villa, through: :villa_inquiry
  def villa
    super || inquiry.try(:villa_inquiry).try(:villa)
  end

  has_many :travelers, -> { order(price_category: :asc, last_name: :asc, first_name: :asc) },
    through: :inquiry

  has_many :booking_pal_reservations,
    through: :inquiry

  after_create :set_booked_state
  after_create :mark_inquiries_as_other_booked

  accepts_nested_attributes_for :travelers

  scope :in_year, ->(year = Date.current.year) {
    where inquiry_id: InquiryUnion.select(:inquiry_id).distinct.in_year(year)
  }

  scope :after,          ->(start) { where "end_date > ?", start }
  scope :booking_number, ->(id) { where inquiry_id: id.to_i }

  scope :search, ->(q) {
    joins(:customer).where "first_name ILIKE :q OR last_name ILIKE :q", q: "%#{q.downcase}%"
  }

  scope :sorting,  ->(o) { reorder(o) }
  scope :currency, ->(c) { joins(:inquiry).where(inquiries: { currency: c }) }

  delegate :adults, :children_under_6, :children_under_12, :persons,
    :start_date, :end_date, :date_range,
    to: :villa_inquiry

  delegate :comment, :currency, :review,
    to: :inquiry

  def self.min_start_date
    joins(:villa_inquiry).minimum("villa_inquiries.start_date")
  end

  def self.max_end_date
    joins(:villa_inquiry).maximum("villa_inquiries.end_date")
  end

  def summary_currency
    currency
  end

  def dates(rentable_type = "villa")
    send(rentable_type.to_s + "_inquiry").dates
  end

  def acceptance_required?
    !new_record? && !admin_booking?
  end

  def self.gap_after(date, scope = Booking, special: false, villa: nil)
    raise ArgumentError, "date must be a Date" unless date.is_a?(Date)

    scope     = scope.joins(:villa_inquiry).booked
    prev_date = scope.where(villa_inquiries: { end_date: ..date })
      .reorder(Arel.sql("villa_inquiries.end_date DESC"))
      .first
      .try(:end_date)
    next_date = scope.where(villa_inquiries: { start_date: date.. })
      .reorder(Arel.sql("villa_inquiries.start_date ASC"))
      .first
      .try(:start_date)

    diff    = (next_date || date) - (prev_date || date)
    minimum = VillaInquiry.minimum_booking_nights date, nil,
      special: special,
      villa:   villa

    return minimum if diff <= 0 || diff > minimum

    [NightsCalculator::ABSOLUTE_MINIMUM_DAYS, diff.to_i].max
  end

  def set_booked_state
    inquiry.set_token
    self.booked_on = DateTime.current
    save!
  end

  def duration
    days
  end

  # sind teilweise noch null werte in der db
  def booked_on
    value = self[:booked_on]
    return value unless value.nil?

    self[:booked_on] = updated_at unless new_record?
  end

  def mark_inquiries_as_other_booked
    Inquiry.joins(:customer).where(customers: { email: customer.email }).find_each do |inquiry|
      unless inquiry == self.inquiry
        inquiry.other_booked = true
        inquiry.save!
      end
    end
  end

  def inquiries
    inquiry.rentable_inquiries
  end

  def dates_for(rentable_type)
    inq = case rentable_type.to_s
    when "villa" then villa_inquiry
    when "boat"  then boat_inquiry
    else raise "invalid rentable type, expected 'villa' or 'boat'"
    end

    [inq.start_date, inq.end_date] if inq
  end
end
