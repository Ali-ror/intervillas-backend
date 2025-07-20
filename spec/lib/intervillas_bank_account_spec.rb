require "rails_helper"

RSpec.describe IntervillasBankAccount do
  let(:spk_hochrein) {
    have_attributes(
      scope:   ["eu"],
      address: include("Sparkasse Hochrhein"),
      iban:    ["DE59 6845 2290 0077 0436 93"],
    )
  }

  let(:kantonal_ch) {
    have_attributes(
      scope:   ["ch"],
      address: include("Zürcher Kantonalbank"),
      iban:    ["CH83 0070 0130 0074 5647 6"],
    )
  }

  let(:kantonal_usd) {
    have_attributes(
      scope:   ["usd"],
      address: include("Zürcher Kantonalbank"),
      iban:    ["CH19 0070 0130 0077 5318 7"],
    )
  }

  let(:chase_bank) {
    have_attributes(
      scope:   ["any"],
      address: include("JPMorgan Chase Bank, N.A."),
      account: ["653 668 221"],
    )
  }

  describe ".accounts" do
    def accounts(type = nil)
      IntervillasBankAccount.accounts(type:)
    end

    context "Intervilla Corp" do
      travel_to_corp_era! offset: 0

      it { expect(accounts).to        contain_exactly(chase_bank) }
      it { expect(accounts(:corp)).to contain_exactly(chase_bank) }
      it { expect(accounts(:gmbh)).to contain_exactly(spk_hochrein, kantonal_ch, kantonal_usd) }
    end

    context "Intervilla GmbH" do
      travel_to_gmbh_era! offset: 1.second

      it { expect(accounts).to        contain_exactly(spk_hochrein, kantonal_ch, kantonal_usd) }
      it { expect(accounts(:corp)).to contain_exactly(chase_bank) }
      it { expect(accounts(:gmbh)).to contain_exactly(spk_hochrein, kantonal_ch, kantonal_usd) }
    end
  end

  describe ".for_currency" do
    def accounts(type = nil)
      IntervillasBankAccount.for_currency(currency, type:)
    end

    context "USD" do
      let(:currency) { Currency::USD }

      context "Intervilla Corp" do
        travel_to_corp_era! offset: 0

        it { expect(accounts).to        contain_exactly(chase_bank) }
        it { expect(accounts(:corp)).to contain_exactly(chase_bank) }
        it { expect(accounts(:gmbh)).to contain_exactly(kantonal_usd) }
      end

      context "Intervilla GmbH" do
        travel_to_gmbh_era! offset: 1.second

        it { expect(accounts).to        contain_exactly(kantonal_usd) }
        it { expect(accounts(:corp)).to contain_exactly(chase_bank) }
        it { expect(accounts(:gmbh)).to contain_exactly(kantonal_usd) }
      end
    end

    context "EUR" do
      let(:currency) { Currency::EUR }

      context "Intervilla Corp" do
        travel_to_corp_era! offset: 0

        it { expect(accounts).to        contain_exactly(chase_bank) }
        it { expect(accounts(:corp)).to contain_exactly(chase_bank) }
        it { expect(accounts(:gmbh)).to contain_exactly(spk_hochrein, kantonal_ch) }
      end

      context "Intervilla GmbH" do
        travel_to_gmbh_era! offset: 1.second

        it { expect(accounts).to        contain_exactly(spk_hochrein, kantonal_ch) }
        it { expect(accounts(:corp)).to contain_exactly(chase_bank) }
        it { expect(accounts(:gmbh)).to contain_exactly(spk_hochrein, kantonal_ch) }
      end
    end
  end
end
