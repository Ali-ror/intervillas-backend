require "rails_helper"

# Die alte Art der Kalkulation soll beibehalten werden, wenn sich in der
# Buchung bereits ein ClearingItem mit der Kategorie :adults befindet.
RSpec.describe Clearing::Villa::Builder do # rubocop:disable RSpec/FilePath
  subject(:clearing) { villa_inquiry.clearing }

  let(:start_date) { Date.new(2020, 1, 1) }
  let(:end_date) { Date.new(2020, 1, 8) }

  context "Buchung mit unterschiedlichen Reisezeiträumen" do
    let!(:villa_inquiry) do
      travelers = [0, 0, -3].map { |offset|
        build(:traveler, start_date: start_date, end_date: end_date + offset.days)
      }

      villa_inquiry = create :villa_inquiry, :legacy_prices,
        travelers: travelers

      create :booking, inquiry: villa_inquiry.inquiry
      villa_inquiry.reload
    end

    def add_traveler(villa_inquiry, traveler_start_date, traveler_end_date)
      create :traveler,
        inquiry_id: villa_inquiry.inquiry_id,
        start_date: traveler_start_date,
        end_date:   traveler_end_date

      items = villa_inquiry.clearing_items
      villa_inquiry.create_clearing_items

      items.each { |ci| ci._destroy = "1" }
      villa_inquiry.save
      villa_inquiry.clearing_items.reload
    end

    describe "Kalkulation" do
      it "enthält zwei Positionen für Erwachsene mit unterschiedlichen Preisen" do
        # - 1.1.-5.1. 3 Personen zu je 66,66 EUR
        expect(clearing.rents).to include have_attributes(category: "adults", amount: 3, price: be_within(0.01).of(66.66))
        # - 5.1.-8.1. 2 Personen zu je 80 EUR
        expect(clearing.rents).to include have_attributes(category: "adults", amount: 2, price: 80)
      end

      shared_examples "Eine Person wird hinzugebucht" do
        before do
          add_traveler(villa_inquiry, traveler_start_date, traveler_end_date)
        end

        it "enthält Positionen für Erwachsene mit ursprünglichen Preisen" do
          ci_attributes.each do |params|
            expect(clearing.rents).to include have_attributes(category: "adults", **params)
          end
        end
      end

      context "Szenario 1: Eine Person wird hinzugebucht vom 1.-5." do
        include_examples "Eine Person wird hinzugebucht" do
          let(:traveler_start_date) { start_date }
          let(:traveler_end_date) { Date.new(2020, 1, 5) }
          let(:ci_attributes) do
            [
              # - 1.1.-5.1. 4 Personen zu je 70 EUR (60 EUR Normalpreis)
              { amount: 4, price: be_within(0.01).of(66.66), normal_price: 60 },
              # - 5.1.-8.1. 2 Personen zu je 80 EUR
              { amount: 2, price: 80 },
            ]
          end
        end
      end

      context "Szenario 2: Eine Person wird hinzugebucht vom 1.-8." do
        include_examples "Eine Person wird hinzugebucht" do
          let(:traveler_start_date) { start_date }
          let(:traveler_end_date) { end_date }
          let(:ci_attributes) do
            [
              # - 1.1.-5.1. 4 Personen zu je 66.66 EUR (60 EUR Normalpreis)
              { amount: 4, price: be_within(0.01).of(66.66), normal_price: 60 },
              # - 5.1.-8.1. 3 Personen zu je 80 EUR (66.66 EUR Normalpreis)
              { amount: 3, price: 80, normal_price: be_within(0.01).of(66.66) },
            ]
          end
        end
      end

      context "Szenario 3: Eine Person wird hinzugebucht vom 2.-6." do
        include_examples "Eine Person wird hinzugebucht" do
          let(:traveler_start_date) { Date.new(2020, 1, 2) }
          let(:traveler_end_date) { Date.new(2020, 1, 6) }
          let(:ci_attributes) do
            [
              # - 1.1.-2.1. 3 Personen zu je 66.66 EUR
              { amount: 3, price: be_within(0.01).of(66.66) },
              # - 2.1.-5.1. 4 Personen zu je 66.66 EUR (60 EUR Normalpreis)
              { amount: 4, price: be_within(0.01).of(66.66), normal_price: 60 },
              # - 5.1.-6.1. 3 Personen zu je 80 EUR (66.66 EUR Normalpreis)
              { amount: 3, price: 80, normal_price: be_within(0.01).of(66.66) },
              # - 6.1.-8.1. 2 Personen zu je 80 EUR
              { amount: 2, price: 80 },
            ]
          end
        end
      end
    end

    # Änderung einer Buchung erzeugt ClearingItems in der gleichen Währung wie die Buchung
    #
    # Achtung! Hier muss der normal_price geprüft werden, da bereits ein clearing_item existieren
    # muss, um das legacy Preismodell zu triggern. Von diesem wird der Preis dann übernommen,
    # aber berechnet wird hier der normal_price.
    context "a booking in USD" do
      around { |ex| Currency.with(Currency::USD, &ex) }

      let!(:villa_inquiry) { create(:villa_inquiry, :legacy_prices, currency: Currency::USD) }
      let(:villa)          { villa_inquiry.villa }
      let(:villa_price)    { villa.villa_price(Currency::USD) }
      let(:single_price)   { villa_price.base_rate / 2 } # :base_rate gilt für 2 Personen

      shared_examples "clearing_items_usd" do
        it "includes clearing item in usd" do
          expect(clearing.rents).to all have_attributes price: have_attributes(currency: Currency::USD)
        end

        it { expect(clearing.rents.first).to have_attributes(normal_price: single_price) }
      end

      include_examples "clearing_items_usd"

      it { expect(single_price).to eq 106.5 }

      context "3 travelers" do
        let(:single_price) { Currency.with(Currency::USD) { villa_price.calculate_base_rate(occupancy: 3) / 3 } }

        context "changing travelers" do
          before do
            clearing.update(Clearing::VillaParams.new.tap { |vp|
              vp.villa     = villa
              vp.travelers = villa_inquiry.travelers + [villa_inquiry.travelers.first.clone]
            }, villa_inquiry.inquiry)
          end

          include_examples "clearing_items_usd"
        end

        context "changing exchange_rate" do
          before do
            Setting.exchange_rate_usd = 1.5
          end

          it { expect(single_price).to eq 104 }

          it "takes new exchange rate when editing booking" do
            clearing.update(Clearing::VillaParams.new.tap { |vp|
              vp.villa     = villa
              vp.travelers = villa_inquiry.travelers + [villa_inquiry.travelers.first.clone]
            }, villa_inquiry.inquiry)

            # Alter Preis für 2 Personen bleibt erhalten, neuer (3 Personen/neuer Umrechnungskurs) wird vorgeschlagen
            expect(clearing.rents.first).to have_attributes(price: 106.5, normal_price: single_price, category: "adults")
          end
        end
      end
    end
  end

  context "Buchung mit einheitlichen Reisezeiträumen" do
    let!(:villa_inquiry) do
      villa_inquiry = create :villa_inquiry, :legacy_prices,
        start_date: start_date,
        end_date:   end_date

      create :booking, inquiry: villa_inquiry.inquiry
      villa_inquiry
    end

    describe "Kalkulation" do
      it "enthält eine Position für Erwachsene" do
        # - 1.1.-8.1. 2 Personen zu je 80 EUR
        expect(clearing.rents).to include have_attributes(category: "adults", amount: 2, price: 80)
        expect(clearing.rents).not_to include have_attributes(category: "base_rate")
        expect(clearing.rents).not_to include have_attributes(category: "additional_adult")
      end

      context "high_season" do
        include_context "high season"

        delegate :villa, to: :villa_inquiry

        it "has high_season" do
          expect(villa.high_seasons).to be_present
          expect(villa_inquiry.discount_finder.high_season).to be_present
        end

        it "enthält eine Position für Erwachsene Hochsaison" do
          # - 1.1.-8.1. 2 Personen -> Erwachsene
          expect(clearing.rents).to include have_attributes(category: "adults_high_season", amount: 2, price: 16)
          expect(clearing.rents).not_to include have_attributes(category: "base_rate_high_season")
          expect(clearing.rents).not_to include have_attributes(category: "additional_adult_high_season")
        end
      end
    end
  end
end
