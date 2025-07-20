# == Schema Information
#
# Table name: boats
#
#  created_at           :datetime         not null
#  description          :text
#  hidden               :boolean          default(FALSE), not null
#  horse_power          :string
#  ical_token           :string           not null
#  id                   :integer          not null, primary key
#  manager_id           :integer
#  matriculation_number :string
#  minimum_days         :integer          default(3), not null
#  model                :string
#  owner_id             :integer
#  updated_at           :datetime         not null
#  url                  :string
#  villa_id             :integer
#
# Indexes
#
#  fk__boats_manager_id       (manager_id)
#  fk__boats_owner_id         (owner_id)
#  fk__boats_villa_id         (villa_id)
#  index_boats_on_hidden      (hidden)
#  index_boats_on_ical_token  (ical_token) UNIQUE
#
# Foreign Keys
#
#  fk_boats_manager_id  (manager_id => contacts.id)
#  fk_boats_owner_id    (owner_id => contacts.id)
#  fk_boats_villa_id    (villa_id => villas.id)
#

class Boat < ApplicationRecord
  translates :description
  include Digineo::I18n

  include Rentable
  include DomainScoped
  include IcalToken
  include Boats::Price

  belongs_to :exclusive_for_villa,
    class_name:  "Villa",
    foreign_key: :villa_id,
    optional:    true # weil NULL erlaubt

  has_and_belongs_to_many :optional_villas,
    class_name: "Villa"

  validates :de_description, presence: true

  has_many :images, -> { order(position: :asc) },
    class_name: "Media::Image",
    as:         "parent"

  has_one :main_image, -> { active.order(position: :asc).limit(1) },
    class_name: "Media::Image",
    as:         "parent"

  scope :optionally_assignable,  -> { includes(:optional_villas).visible.where(villa_id: nil) }
  scope :exclusively_assignable, -> { optionally_assignable.where("id NOT IN (SELECT boat_id from boats_villas)") }

  scope :available_between, ->(start_date, end_date) {
    booked_ids  = BoatInquiry.booked.clashes(start_date, end_date).select(:boat_id)
    blocked_ids = Blocking.where.not(boat_id: nil).clashes(start_date, end_date).select(:boat_id)
    diff        = (end_date - start_date).floor + 1

    where("boats.minimum_days <= ?", diff)
      .where.not(id: booked_ids)
      .where.not(id: blocked_ids)
  }
  # Boot mit Mietpreis ist aktiv
  scope :active,          -> { joins(:prices).where(boat_prices: { subject: "daily" }).distinct }
  scope :for_occupancies, -> { visible }
  scope :visible,         -> { where(hidden: false) }
  scope :hidden,          -> { where(hidden: true) }
  scope :three_random,    -> { visible.where(id: Boat.active.select(:id)).order(Arel.sql("RANDOM()")).limit(3) }

  UNBOOKABLE_QUERY = <<~SQL.squish.freeze
    select * from boats
    where
      (hidden = 'f')      and
      (villa_id is null)  and
      (id not in (select distinct boat_id from boats_villas))
  SQL

  scope :unbookable, -> { find_by_sql UNBOOKABLE_QUERY }

  delegate :list_name, :display_name, :admin_display_name, :formatted_matriculation_number,
    to: :boat_name_builder

  def villas
    optional_villas.to_a.push(exclusive_for_villa).compact
  end

  def no_villa?
    villas.empty?
  end

  def boat_name_builder
    @boat_name_builder ||= BoatNameBuilder.from_boat(self)
  end

  def inclusive?
    exclusive_for_villa.present?
  end

  def optional?
    !inclusive?
  end

  def hide!
    transaction do
      optional_villas.clear
      self.villa_id = nil
      update_attribute :hidden, true
    end
  end

  def assigned_to?(villa)
    optional_villas.include? villa
  end

  def active?
    !hidden?
  end
end
