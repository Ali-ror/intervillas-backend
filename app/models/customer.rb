# == Schema Information
#
# Table name: customers
#
#  id                     :integer          not null, primary key
#  address                :string
#  appnr                  :string
#  bank_account_number    :string
#  bank_account_owner     :string
#  bank_code              :string
#  bank_name              :string
#  city                   :string
#  country                :string
#  email                  :string
#  first_name             :string           not null
#  last_name              :string           not null
#  locale                 :string
#  newsletter             :boolean          default(FALSE), not null
#  note                   :string
#  phone                  :string
#  postal_code            :string
#  state_code             :string
#  title                  :string
#  travel_insurance       :integer          default("unknown"), not null
#  us_bank_routing_number :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Customer < ApplicationRecord
  has_one :inquiry
  has_one :booking, through: :inquiry

  has_many :messages, as: :recipient

  TITLE_MAPPING = {
    "Herr" => { "en" => "Mr.",  "de" => "Herr" },
    "Frau" => { "en" => "Mrs.", "de" => "Frau" },
  }.freeze

  enum :travel_insurance, {
    unknown:     0,
    insured:     1,
    not_insured: 2,
  }, prefix: false, scopes: false, default: "unknown"

  include BankAccountInformation
  has_bank_account

  # handled by BankAccountInformation
  strip_attributes except: %i[
    bank_account_number
    bank_code
  ]

  before_create :save_locale

  def save_locale
    self.locale ||= I18n.locale.to_s
  end

  def title
    TITLE_MAPPING.fetch(super, {}).fetch(locale, "de")
  end

  def salutation
    return "Dear #{title} #{last_name}".squish if locale == "en"
    return name                                if title.blank?

    "Sehr geehrte#{title == 'Herr' ? 'r' : ''} #{title} #{last_name}"
  end

  def name
    [first_name, last_name].join " "
  end
  alias to_s name

  def email_addresses
    [email]
  end

  concerning :CSV do
    included do
      scope :newsletter_export, -> {
        select("distinct on (email) *")
          .order(:email, :address, updated_at: :desc)
      }

      comma do
        locale("Sprachcode")
        email               { _1.to_s.strip } # rubocop:disable Layout/ExtraSpacing
        newsletter("Newsletter angemeldet?") { _1 ? "JA" : "NEIN" }
        title               { _1.to_s.strip }
        first_name          { _1.to_s.strip }
        last_name           { _1.to_s.strip }
        address             { _1.to_s.strip }
        appnr               { _1.to_s.strip }
        postal_code         { _1.to_s.strip }
        city                { _1.to_s.strip }
        country             { _1.to_s.strip }
        updated_at("Stand") { _1.strftime("%d.%m.%Y") }
      end
    end
  end
end
