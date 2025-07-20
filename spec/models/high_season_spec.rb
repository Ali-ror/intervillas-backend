require "rails_helper"

RSpec.describe HighSeason do
  it { is_expected.to have_and_belong_to_many :villas }
  it { is_expected.to have_many(:bookings).through(:villas) }

  describe "#name" do
    subject(:high_season) { HighSeason.new(starts_on: starts_on, ends_on: ends_on) }

    context "2017-18" do
      let(:starts_on) { Date.parse("2017-12-15") }
      let(:ends_on)   { Date.parse("2018-05-31") }

      its(:name) { is_expected.to eq "2017-18" }
    end

    context "2018-19" do
      let(:starts_on) { Date.parse("2018-12-15") }
      let(:ends_on)   { Date.parse("2019-05-31") }

      its(:name) { is_expected.to eq "2018-19" }
    end
  end

  describe "factory" do
    subject(:high_season) { create :high_season }

    it { is_expected.to be_valid }
  end
end
