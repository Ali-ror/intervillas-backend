require "rails_helper"

RSpec.describe BoatPrice do
  subject(:price) { build :boat_price, subject: "daily" }

  it { is_expected.to have_db_column :boat_id }
  it { is_expected.to belong_to(:boat) }

  it { is_expected.to have_db_column :subject }
  it { is_expected.to validate_presence_of :subject }
  it { is_expected.to allow_values(*BoatPrice::SUBJECTS).for(:subject) }

  it { is_expected.to have_db_column :amount }
  it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0).only_integer }

  it { is_expected.to have_db_column :value }
  it { is_expected.to validate_numericality_of(:value).is_greater_than_or_equal_to(0) }
  it { is_expected.to validate_presence_of :value }

  it { is_expected.to have_db_column :currency }
  it { is_expected.to validate_presence_of :currency }
  it { is_expected.to allow_values(*Currency::CURRENCIES).for(:currency) }

  context "deposits" do
    subject(:price) { build :boat_price, subject: "deposit" }

    it { is_expected.to validate_absence_of(:amount) }
  end

  context "training" do
    subject(:price) { build :boat_price, subject: "training" }

    it { is_expected.to validate_absence_of(:amount) }
  end

  describe "#to_s" do
    it "prints its value" do
      expect(price.to_s).to eql(price.value.to_s)
    end
  end
end
