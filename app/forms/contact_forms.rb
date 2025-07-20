#
# Obacht: "Contact" nicht im Sinne einer Kontaktaufnahme, sondern im Sinne
#         eines Eigentümers bzw. einer Verwaltung
#
module ContactForms
  class Base < ModelForm
    from_model :contact

    def self.model_name
      Contact.model_name
    end

    def form_id
      self.class.to_s.demodulize.underscore
    end
  end

  class Basics < Base
    attribute :gender, String
    validates :gender,
      presence:  true,
      inclusion: { in: %w[c m f] }

    attribute :company_name, String
    validates :company_name,
      presence: { if: :company? }

    attribute :last_name, String
    validates :last_name,
      presence: { unless: :company? }

    attribute :first_name,  String
    attribute :address,     String
    attribute :city,        String
    attribute :zip,         String
    attribute :country,     String
    attribute :phone,       String

    private

    def company?
      gender == "c"
    end
  end

  class Billing < Base
    attribute :tax_id_number, String
    validate :unique_tax_id

    attribute :commission, Integer
    validates :commission,
      numericality: {
        only_integer:             true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to:    100, # ??
      }

    attribute :agency_fee, Integer
    validates :agency_fee,
      presence:     true,
      numericality: { greater_than_or_equal_to: 0 }

    attribute :net, Axiom::Types::Boolean

    attribute :locale, String
    validates :locale,
      presence:  true,
      inclusion: { in: %w[de en] }

    attribute :email_addresses, String
    attribute :wants_auto_booking_confirmation_mail, Axiom::Types::Boolean

    attribute :payout_reminder_days, Integer
    validates :payout_reminder_days,
      numericality: {
        only_integer:             true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to:    30,
        allow_blank:              true,
      }

    def init_virtual
      super
      self.email_addresses = (model.emails || []).join("\n")
    end

    def save
      model.attributes = attributes.except(:email_addresses)
      model.emails     = email_addresses
      model.save
    end

    private

    def unique_tax_id
      return if tax_id_number.blank?
      return unless (u = Contact.find_by(tax_id_number: tax_id_number))

      errors.add :tax_id_number, :taken if u.id != model.id
    end
  end

  class BankAccount < Base
    include BankAccountInformation

    has_bank_account \
      strip_data: false, # BankAccountInformation versucht Hooks in before_validation
      copy_owner: false  # Callback anzulegen. Das geht hier nicht.

    delegate :first_name, :last_name, to: :model

    attribute :bank_account_owner,  String
    attribute :bank_account_number, String
    attribute :bank_address,        String
    attribute :bank_code,           String
    attribute :bank_name,           String
    attribute :bank_routing_number, String

    attribute :usd_bank_account_owner,  String
    attribute :usd_bank_account_number, String
    attribute :usd_bank_address,        String
    attribute :usd_bank_code,           String
    attribute :usd_bank_name,           String
    attribute :usd_bank_routing_number, String

    def valid?
      copy_owner_information
      strip_bank_information

      self.usd_bank_account_owner = [first_name, last_name].join(" ") if usd_bank_account_owner.blank?

      self.usd_bank_account_number = usd_bank_account_number.to_s.gsub(/\W/, "").strip.presence
      self.usd_bank_code           = usd_bank_code.to_s.gsub(/\W/, "").strip.presence

      super
    end
  end
end
