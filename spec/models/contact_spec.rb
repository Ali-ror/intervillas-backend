require "rails_helper"

RSpec.describe Contact do
  %w[gender first_name last_name address zip city country emails phone].each do |col|
    it { is_expected.to have_db_column col }
  end

  it { is_expected.not_to validate_presence_of "gender" }

  context "with company name" do
    before { subject.company_name = Faker::Company.name }

    it { is_expected.to validate_presence_of "gender" }
  end

  it { is_expected.to allow_value("c", "m", "f", nil).for(:gender) }
  it { is_expected.not_to allow_value("test", "Herr").for(:gender) }

  it { is_expected.to allow_value("", nil).for(:tax_id_number) }

  it { is_expected.to have_many :owned_villas }
  it { is_expected.to have_many :managed_villas }
  it { is_expected.to have_many :owned_boats }
  it { is_expected.to have_many :managed_boats }

  it { is_expected.to have_and_belong_to_many :users }

  describe "bank_account(currency)" do
    let(:eur_attributes) {
      {
        account_owner:  "EUR Owner",
        account_number: "EUR Account Number",
        name:           "EUR Name",
        address:        "EUR Address",
        code:           "EUR Code",
        routing_number: "EUR Routing Number",
      }
    }
    let(:usd_attributes) {
      {
        account_owner:  "USD Owner",
        account_number: "USD Account Number",
        name:           "USD Name",
        address:        "USD Address",
        code:           "USD Code",
        routing_number: "USD Routing Number",
      }
    }
    let(:nil_attributes) {
      {
        account_owner:  nil,
        account_number: nil,
        name:           nil,
        address:        nil,
        code:           nil,
        routing_number: nil,
      }
    }
    let(:eur_contact_attributes) { eur_attributes.transform_keys { |k| "bank_#{k}" } }
    let(:usd_contact_attributes) { usd_attributes.transform_keys { |k| "usd_bank_#{k}" } }

    context "two accounts" do
      let(:contact) { create :contact, **eur_contact_attributes, **usd_contact_attributes }

      context "default currency" do
        subject(:bank_account) { contact.bank_account }

        it { is_expected.to have_attributes eur_attributes }
      end

      context "eur" do
        subject(:bank_account) { contact.bank_account(Currency::EUR) }

        it { is_expected.to have_attributes eur_attributes }
      end

      context "usd" do
        subject(:bank_account) { contact.bank_account(Currency::USD) }

        it { is_expected.to have_attributes usd_attributes }
      end
    end

    context "only eur account" do
      let(:contact) { create :contact, **eur_contact_attributes }

      context "default currency" do
        subject(:bank_account) { contact.bank_account }

        it { is_expected.to have_attributes eur_attributes }
      end

      context "eur" do
        subject(:bank_account) { contact.bank_account(Currency::EUR) }

        it { is_expected.to have_attributes eur_attributes }
      end

      context "usd" do
        subject(:bank_account) { contact.bank_account(Currency::USD) }

        it { is_expected.to have_attributes nil_attributes }
      end
    end

    context "only usd account" do
      let(:contact) { create :contact, **usd_contact_attributes }

      context "default currency" do
        subject(:bank_account) { contact.bank_account }

        it { is_expected.to have_attributes nil_attributes }
      end

      context "eur" do
        subject(:bank_account) { contact.bank_account(Currency::EUR) }

        it { is_expected.to have_attributes nil_attributes }
      end

      context "usd" do
        subject(:bank_account) { contact.bank_account(Currency::USD) }

        it { is_expected.to have_attributes usd_attributes }
      end
    end
  end
end
