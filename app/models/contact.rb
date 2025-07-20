# == Schema Information
#
# Table name: contacts
#
#  id                                   :integer          not null, primary key
#  address                              :string
#  agency_fee                           :decimal(8, 2)    default(15.0), not null
#  bank_account_number                  :string
#  bank_account_owner                   :string
#  bank_address                         :string
#  bank_code                            :string
#  bank_name                            :string
#  bank_routing_number                  :string
#  city                                 :string
#  commission                           :integer
#  company_name                         :string
#  country                              :string
#  emails                               :string           is an Array
#  first_name                           :string
#  gender                               :string
#  last_name                            :string
#  locale                               :string           default("de"), not null
#  net                                  :boolean          default(FALSE), not null
#  payout_reminder_days                 :integer
#  phone                                :string
#  tax_id_number                        :string
#  usd_bank_account_number              :string
#  usd_bank_account_owner               :string
#  usd_bank_address                     :string
#  usd_bank_code                        :string
#  usd_bank_name                        :string
#  usd_bank_routing_number              :string
#  wants_auto_booking_confirmation_mail :boolean          default(TRUE), not null
#  zip                                  :string
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#

class Contact < ApplicationRecord
  include Currency::Model

  currency_values :agency_fee, currency: "EUR"

  validates :gender,
    presence:  { if: :requires_gender? },
    inclusion: { in: %w[c m f], allow_nil: true }

  validates :last_name,
    presence: { if: :requires_name? }

  strip_attributes only: %i[
    bank_account_number bank_account_owner bank_address bank_code bank_name bank_routing_number
    usd_bank_account_number usd_bank_account_owner usd_bank_address usd_bank_code usd_bank_name usd_bank_routing_number
    tax_id_number gender company_name first_name last_name phone address city zip country
    payout_reminder_days
  ]

  has_many :messages, as: :recipient
  has_and_belongs_to_many :users

  has_many :owned_villas, foreign_key: :owner_id, class_name: "Villa", dependent: :nullify
  has_many :owned_boats, foreign_key: :owner_id, class_name: "Boat", dependent: :nullify

  has_many :managed_villas, foreign_key: :manager_id, class_name: "Villa", dependent: :nullify
  has_many :managed_boats, foreign_key: :manager_id, class_name: "Boat", dependent: :nullify

  has_many :cables

  has_many :clearing_reports
  has_many :owned_villa_inquiries, class_name: "VillaInquiry", source: :villa_inquiries, through: :owned_villas
  has_many :owned_boat_inquiries, class_name: "BoatInquiry", source: :boat_inquiries, through: :owned_boats

  scope :active, -> {
    joined = left_joins(:owned_villas, :managed_villas, :owned_boats, :managed_boats)
    joined.merge(Villa.active)
      .or(joined.merge(Boat.visible))
      .or(joined.where(managed_villas_contacts: { active: true }))
      .or(joined.where(managed_boats_contacts: { hidden: false }))
      .distinct
  }

  def self.inactive # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    select do |c|
      c.owned_villas.none?(&:active) &&
        c.managed_villas.none?(&:active) &&
        c.owned_boats.none? { |b| !b.hidden } &&
        c.managed_boats.none? { |b| !b.hidden }
    end
  end

  def title
    I18n.t gender, scope: "titles"
  end

  def salutation
    case gender
    when "m", "f"
      I18n.t(gender, scope: "salutation") % last_name
    when "c", nil
      I18n.t("c", scope: "salutation")
    end
  end

  def genderless?
    gender == "c" # Company
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def to_s
    c_name = company_name.presence
    p_name = name.presence
    return c_name if c_name == p_name

    [c_name, p_name].compact.join(", ")
  end

  def display_name
    [last_name, first_name].map(&:presence).compact.join(", ")
  end

  def tax_id_number=(val)
    super val.presence
  end

  def email_addresses
    @email_addresses ||= [*emails].grep(Devise.email_regexp)
  end

  def emails=(str)
    str = str.split(/[[:space:]]+/) unless str.is_a?(Array)
    super str.grep(Devise.email_regexp)
  end

  def rentables
    ContactRentable
      .where(active: true)
      .where("owner_id = :id or manager_id = :id", id: id)
  end

  def has_access?
    return @has_access if defined?(@has_access)

    @has_access = begin
      user_email     = users.with_access.pluck(:email) || []
      contract_email = emails || []
      (user_email & contract_email).any?
    end
  end

  BankAccount = Struct.new :account_owner, :account_number, :name, :address, :code, :routing_number,
    keyword_init: true

  def bank_account(currency = Currency::EUR)
    if currency == Currency::USD
      return BankAccount.new(
        account_owner:  usd_bank_account_owner,
        account_number: usd_bank_account_number,
        name:           usd_bank_name,
        address:        usd_bank_address,
        code:           usd_bank_code,
        routing_number: usd_bank_routing_number,
      )
    end

    BankAccount.new(
      account_owner:  bank_account_owner,
      account_number: bank_account_number,
      name:           bank_name,
      address:        bank_address,
      code:           bank_code,
      routing_number: bank_routing_number,
    )
  end

  private

  def requires_name?
    gender != "c"
  end

  def requires_gender?
    company_name.present?
  end
end
