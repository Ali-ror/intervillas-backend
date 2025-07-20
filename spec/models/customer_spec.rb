require "rails_helper"

RSpec.describe Customer do
  it { is_expected.to have_one :inquiry }
  it { is_expected.to have_one :booking }

  describe "bank account" do
    subject { build :customer }

    [
      [nil, nil, nil, nil],
      ["", "", "", ""],
      ["Foo name", "Bar name", "1234", "12345678"],
      ["Baz name", "Snafu", "ABCDEF01", "DE00111222333444555"],

      # there's no actual validation here...
      ["§=)§", '\\!(/"', "1234", "12345678a"],
      ["", nil, "zABCDEF01", "DE00111222333444555"],
    ].each do |owner, bank, bic, iban|
      context "with valid information: #{bic.inspect}/#{iban.inspect}" do
        before do
          subject.bank_account_owner  = owner
          subject.bank_name           = bank
          subject.bank_account_number = bic
          subject.bank_code           = iban
        end

        it { is_expected.to be_valid }
      end
    end
  end

  context "with valid attributes" do
    subject(:customer) { build :customer }

    describe "with german locale" do
      before do
        customer.locale = "de"
      end

      it "should return german salutation" do
        expect(customer.salutation).to eq "Sehr geehrter Herr #{customer.last_name}"
      end

      it "should return german salutation for a woman" do
        customer.title = "Frau"
        expect(customer.salutation).to eq "Sehr geehrte Frau #{customer.last_name}"
      end
    end

    describe "with english locale" do
      before do
        customer.locale = "en"
      end

      it "should return english salutation" do
        expect(customer.salutation).to eq "Dear Mr. #{customer.last_name}"
      end

      it "should return german salutation for a woman" do
        customer.title = "Frau"
        expect(customer.salutation).to eq "Dear Mrs. #{customer.last_name}"
      end
    end
  end
end
