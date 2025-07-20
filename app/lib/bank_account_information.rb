# used in booking + user model
module BankAccountInformation
  extend ActiveSupport::Concern

  LEGACY_ACCOUNT_NUMBER_RE  = /\A\d{,10}\z/
  LEGACY_BANK_CODE_RE       = /\A\d{8}\z/

  IBAN_ACCOUNT_NUMBER_RE    = /\A[A-Z]{2}\d{2}[0-9A-Z]{,30}\z/
  BIC_BANK_CODE_RE          = /\A[A-Z]{6}[0-9A-Z]{2}([0-9A-Z]{3})?\z/

  module ClassMethods
    def has_bank_account(options = {}) # rubocop:disable Naming/PredicateName
      options.reverse_merge! \
        strip_data: true,
        copy_owner: true

      before_validation :strip_bank_information if options[:strip_data]

      return unless options[:copy_owner]

      before_validation :copy_owner_information
    end
  end

  def copy_owner_information
    return if bank_account_owner.present?

    self.bank_account_owner = [first_name, last_name].join(" ")
  end

  def strip_bank_information
    self.bank_account_number = bank_account_number.to_s.gsub(/\W/, "").strip.presence
    self.bank_code           = bank_code.to_s.gsub(/\W/, "").strip.presence
  end

  def swift_bank_account?
    blank_bank_account? || matching?(IBAN_ACCOUNT_NUMBER_RE, BIC_BANK_CODE_RE)
  end

  private

  def blank_bank_account?
    bank_account_number.blank? && bank_code.blank?
  end

  def matching?(account_re, bank_code_re)
    # ATTN: bank_account_number denotes SWIFT-BIC, and bank_code denotes IBAN!
    # Not sure when or how that happened... needs to be refactored/renamed.
    bank_code.to_s.upcase =~ account_re &&
      bank_account_number.to_s.upcase =~ bank_code_re
  end
end
