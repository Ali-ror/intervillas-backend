require "rails_helper"

RSpec.describe CustomerForms do
  describe "ForInquiry" do
    subject(:form) { CustomerForms::ForInquiry.from_customer Customer.new }

    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :first_name }
    it { is_expected.to validate_presence_of :last_name }
    it { is_expected.to validate_presence_of :email }
    it { is_expected.to validate_confirmation_of :email }

    it { is_expected.to allow_value("test@example.com").for(:email) }
    it { is_expected.not_to allow_value("test").for(:email) }
  end

  describe "ForBooking" do
    subject(:form) { CustomerForms::ForBooking.new }

    %i[address appnr postal_code city country].each do |col|
      it { is_expected.to validate_presence_of col }
    end

    describe "validates state_code depending on country" do
      it "for a country with known divisions" do
        form.country = "CH" # Switzerland has cantons
        expect(form).to validate_presence_of :state_code
        expect(form).to validate_inclusion_of(:state_code).in_array %w[ZH BS]
      end

      it "for a country without known divisions" do
        form.country = "MX" # Mexico has "federative entities", but we don't have a list
        expect(form).to validate_presence_of :state_code
      end

      it "for a country without divisions" do
        form.country = "TV" # Tuvalu
        expect(form).to validate_absence_of :state_code
      end
    end
  end

  describe "Admin" do
    let(:inquiry) { create_villa_inquiry.inquiry }
    let(:customer) { inquiry.customer }

    describe ".from_inquiry" do
      subject(:admin_form) { CustomerForms::Admin.from_inquiry(inquiry) }

      describe "loads attributes from customer" do
        it { expect(admin_form.first_name).to eq customer.first_name }
      end
    end

    describe ".from_customer" do
      subject(:admin_form) { CustomerForms::Admin.from_customer(customer) }

      describe "loads attributes from customer" do
        it { expect(admin_form.first_name).to eq customer.first_name }
      end
    end

    describe "#model_name" do
      it { expect(CustomerForms::Admin.model_name).to eq Customer.model_name }
    end
  end
end
