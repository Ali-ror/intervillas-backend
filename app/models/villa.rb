# == Schema Information
#
# Table name: villas
#
#  id                      :integer          not null, primary key
#  active                  :boolean          not null
#  additional_properties   :jsonb            not null
#  build_year              :string
#  buyable                 :boolean          not null
#  country                 :string
#  energy_cost_calculation :integer          default("defer"), not null
#  ical_token              :string           not null
#  last_renovation         :string
#  living_area             :integer          not null
#  locality                :string
#  minimum_booking_nights  :integer          default(7), not null
#  minimum_people          :integer          default(2), not null
#  name                    :string           not null
#  phone                   :string
#  pool_orientation        :string(2)
#  postal_code             :string
#  postal_code_plus_four   :string(10)
#  region                  :string
#  safe_code               :string           not null
#  street                  :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  manager_id              :integer
#  owner_id                :integer
#
# Indexes
#
#  fk__villas_manager_id       (manager_id)
#  fk__villas_owner_id         (owner_id)
#  index_villas_on_ical_token  (ical_token) UNIQUE
#  index_villas_on_name        (name) UNIQUE
#
# Foreign Keys
#
#  fk_villas_manager_id  (manager_id => contacts.id)
#  fk_villas_owner_id    (owner_id => contacts.id)
#

class Villa < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Digineo::CountableTags
  include Villas::Price
  include Villas::Specials
  include Villas::Reviews
  include Villas::Media
  include Villas::Boats
  include Villas::Areas
  include Villas::Descriptions
  include Villas::PropertyLocations
  include Villas::AdditionalProperties

  include Rentable
  include DomainScoped
  include IcalToken

  # Presets for Inquiry#energy_cost_calculation. Value will be copied into
  # Inquiry, unless Inquiry has an value marked as override or legacy.
  #
  # @see {Inqiury::EnergyCost} for further details
  enum :energy_cost_calculation, {
    defer:    0, # calculation deferred to billing
    usage:    1, # billing will only show meter-reading + price per kWh input fields
    flat:     2, # billing will only show fix-price input field
    included: 3, # billing will not show energy price fields
  }, prefix: true, scopes: false

  extend ActsAsGeocodable
  acts_as_geocodable normalize_address: true

  validates :name, :living_area,
    presence: true

  validates :name,
    uniqueness: true

  validates :active, :buyable,
    inclusion: { in: [true, false] }

  validates :minimum_people,
    absense_of_child_prices: true

  strip_attributes only: %i[name pool_orientation phone],
    collapse_spaces: true

  strip_attributes only: %i[safe_code],
    allow_empty:     true,
    collapse_spaces: true

  delegate :commission,
    to:        :owner,
    prefix:    true,
    allow_nil: true

  has_and_belongs_to_many :high_seasons

  has_many :calendars,
    index_errors: true

  has_one :booking_pal_product,
    class_name:  "MyBookingPal::Product",
    foreign_key: :id,
    inverse_of:  :villa

  accepts_nested_attributes_for :calendars,
    allow_destroy: true

  scope :last_minute,     -> { joins(:specials) }
  scope :active,          -> { where active: true }
  scope :inactive,        -> { where active: false }
  scope :for_occupancies, -> { active }

  # TODO: people parameter mit beds_count vergleichen
  scope :search, ->(start_date, end_date, _people = 2, _rooms = 1) {
    booked  = VillaInquiry.clashes(start_date, end_date).booked.select(:villa_id)
    blocked = Blocking.clashes(start_date, end_date).select_villa_ids
    nights  = (end_date.to_date - start_date.to_date).to_i

    # NOTE: booked/blocked are non-trivial sub-queries,
    #       `where.not(id: [*booked, *blocked])` won't work
    where.not(id: booked).where.not(id: blocked)
      .where(minimum_booking_nights: ..nights)
  }

  scope :with_owner_manager,   -> { includes(:manager, :owner) }
  scope :having_cancellations, -> { joins(inquiries: :cancellation).uniq }

  include HasRoute
  has_route

  after_commit on: %i[create update] do
    next unless booking_pal_product
    next if Rails.env.development? && booking_pal_product.foreign_id.nil?

    booking_pal_product.update_remote!
  end

  def self.random(limit)
    unscoped.active.order(Arel.sql("random()")).limit(limit)
  end

  def to_s
    name
  end

  alias admin_display_name to_s
  alias display_name to_s

  def find_areas(name)
    areas.select do |area|
      area.category_id == Category.where(name:).first.id
    end
  end

  def season_types
    SeasonDiscount.types_for_villa(self)
  end

  def gap_after(date)
    if date.blank?
      return VillaInquiry.minimum_booking_nights Date.current, nil,
        special: current_special?,
        villa:   self
    end

    date = Date.parse(date) unless date.is_a?(Date)
    date = Date.current if date < Date.current

    bookings.gap_after date, bookings,
      special: special_for?(date),
      villa:   self
  end

  def to_param
    "#{id}-#{route.try(:path) || name}"
  end

  def postal_code_plus_four
    val = super
    return val if val&.start_with?(postal_code)
    return ""  if country != "US"

    val                        = Usps.lookup_zip_plus_four(self)
    self.postal_code_plus_four = val
    update postal_code_plus_four: val if persisted?

    super
  end

  def redirect_unlocalized
    if request.format.html?
      if params[:id].blank?
        redirect_to villas_url, status: :moved_permanently
      else
        redirect_to villa_url(villa), status: :moved_permanently
      end
    end
  end

  def self.unavailable_dates
    villa_id = Villa.active.pluck(:id)
    booked_ranges = VillaInquiry.where(villa_id: villa_id).pluck(:start_date, :end_date)
    blocked_ranges = Blocking.where(villa_id: villa_id).pluck(:start_date, :end_date)
    all_ranges = (booked_ranges + blocked_ranges).compact
    unavailable = all_ranges.flat_map do |start_date, end_date| (start_date..end_date).to_a
    end.uniq
  end

end
