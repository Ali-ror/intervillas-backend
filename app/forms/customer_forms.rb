module CustomerForms
  module Common
    extend ActiveSupport::Concern

    included do
      attribute :locale, String, default: "de"
      validates :locale,
        presence:  true,
        inclusion: { in: %w[de en] }

      attribute :title, String
      validates :title, presence: true

      attribute :first_name, String
      validates :first_name, presence: true

      attribute :last_name, String
      validates :last_name, presence: true

      attribute :email, String
      validates :email,
        presence:     true,
        email_format: true

      attribute :phone, String
    end
  end

  class ForInquiry < ModelForm
    include Common

    from_model :customer

    attribute :locale, String

    attribute :email_confirmation, Boolean
    validates :email_confirmation,
      email_format: true,
      presence:     true

    validates :email,
      confirmation: true

    validates :phone,
      presence: true

    attribute :newsletter, Boolean

    def to_ar
      attrs = attributes.reject { |key, _value|
        %w[email_confirmation currency].include? key.to_s
      }

      customer.attributes = attrs
      customer
    end

    def save
      to_ar.save!
      true
    end
  end

  class ForExternalBooking < ModelForm
    attr_accessor :first_name, :last_name

    attribute :address
    attribute :appnr
    attribute :postal_code
    attribute :city
    attribute :country
    attribute :state_code
    attribute :travel_insurance, String

    attribute :bank_account_owner
    attribute :bank_account_number
    attribute :bank_name
    attribute :bank_code
    attribute :us_bank_routing_number
  end

  class ForBooking < ForExternalBooking
    validates :address, presence: true
    validates :appnr, presence: true
    validates :postal_code, presence: true
    validates :city, presence: true
    validates :country, presence: true
    validates :state_code, state_code: true

    validates :travel_insurance,
      presence:  true,
      inclusion: { in: :allowed_travaler_insurances }

    def allowed_travaler_insurances
      %w[insured not_insured]
    end
  end

  class AdminOffer < ModelForm
    include Common

    from_model :customer

    attribute :address
    attribute :appnr
    attribute :postal_code
    attribute :city
    attribute :country
    attribute :state_code
    attribute :note

    attribute :bank_account_owner
    attribute :bank_account_number
    attribute :bank_name
    attribute :bank_code

    attribute :us_bank_routing_number

    attribute :travel_insurance
    validates :travel_insurance,
      presence: true

    # def save
    #   customer.attributes = attributes
    #   customer.save!
    # end
  end

  module AdminCommon
    extend ActiveSupport::Concern

    included do
      from_model :customer
      attribute :note
    end

    class_methods do
      def from_inquiry(inquiry)
        customer = inquiry.customer
        from_customer customer
      end
    end

    def allowed_travaler_insurances
      Customer.travel_insurances.keys
    end
  end

  class Admin < ForBooking
    include Common
    include AdminCommon
  end

  class AdminExternal < ForExternalBooking
    include Common
    include AdminCommon
  end
end
