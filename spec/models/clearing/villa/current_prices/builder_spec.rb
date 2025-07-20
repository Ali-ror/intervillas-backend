require "rails_helper"

RSpec.describe Clearing::Villa::Builder do # rubocop:disable RSpec/FilePath
  subject(:clearing) { villa_inquiry.clearing }

  let(:start_date) { Date.new(2020, 1, 1) }
  let(:end_date)   { Date.new(2020, 1, 8) }
  let(:external)   { false }

  context "Buchung mit unterschiedlichen Reisezeiträumen" do
    let!(:villa_inquiry) do
      travelers = [0, 0, -3].map { |offset|
        build(:traveler, start_date: start_date, end_date: end_date + offset.days)
      }

      villa_inquiry = create :villa_inquiry,
        travelers: travelers,
        external:  external

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
        # - 1.1.-5.1. 3 Personen
        expect(clearing.rents).to include have_attributes(category: "base_rate", amount: 1, price: 160)
        expect(clearing.rents).to include have_attributes(category: "additional_adult", amount: 1, price: 40)
        # - 5.1.-8.1. 2 Personen
        expect(clearing.rents).to include have_attributes(category: "base_rate", amount: 1, price: 160)
      end

      shared_examples "Eine Person wird hinzugebucht" do
        before do
          add_traveler(villa_inquiry, traveler_start_date, traveler_end_date)
        end

        it "enthält Positionen für Erwachsene mit ursprünglichen Preisen" do
          ci_attributes.each do |params|
            expect(clearing.rents).to include have_attributes(**params)
          end
        end
      end

      context "Szenario 1: Eine Person wird hinzugebucht vom 1.-5." do
        include_examples "Eine Person wird hinzugebucht" do
          let(:traveler_start_date) { start_date }
          let(:traveler_end_date) { Date.new(2020, 1, 5) }
          let(:ci_attributes) do
            [
              # - 1.1.-5.1. 4 Personen -> Grundpreis und 2 Erwachsene
              { start_date: Date.new(2020, 1, 1), category: "base_rate", amount: 1, price: 160 },
              { category: "additional_adult", amount: 2, price: 40 },
              # - 5.1.-8.1. 2 Personen -> Grundpreis
              { start_date: Date.new(2020, 1, 5), category: "base_rate", amount: 1, price: 160 },
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
              # - 1.1.-5.1. 4 Personen -> Grundpreis und 2 Erwachsene
              { start_date: Date.new(2020, 1, 1), category: "base_rate", amount: 1, price: 160 },
              { start_date: Date.new(2020, 1, 1), category: "additional_adult", amount: 2, price: 40 },
              # - 5.1.-8.1. 3 Personen -> Grundpreis und 1 Erwachsener
              { start_date: Date.new(2020, 1, 5), category: "base_rate", amount: 1, price: 160 },
              { start_date: Date.new(2020, 1, 5), category: "additional_adult", amount: 1, price: 40 },
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
              # - 1.1.-2.1. 3 Personen -> Grundpreis und 1 Erwachsener
              { start_date: Date.new(2020, 1, 1), category: "base_rate", amount: 1, price: 160 },
              { start_date: Date.new(2020, 1, 1), category: "additional_adult", amount: 1, price: 40 },
              # - 2.1.-5.1. 4 Personen-> Grundpreis und 2 Erwachsene
              { start_date: Date.new(2020, 1, 2), category: "base_rate", amount: 1, price: 160 },
              { start_date: Date.new(2020, 1, 2), category: "additional_adult", amount: 2, price: 40 },
              # - 5.1.-6.1. 3 Personen -> Grundpreis und 1 Erwachsener
              { start_date: Date.new(2020, 1, 5), category: "base_rate", amount: 1, price: 160 },
              { start_date: Date.new(2020, 1, 5), category: "additional_adult", amount: 1, price: 40 },
              # - 6.1.-8.1. 2 Personen -> Grundpreis
              { start_date: Date.new(2020, 1, 6), category: "base_rate", amount: 1, price: 160 },
            ]
          end
        end
      end
    end

    # Änderung einer Buchung erzeugt ClearingItems in der gleichen Währung wie die Buchung
    context "a booking in USD" do
      around { |ex| Currency.with(Currency::USD, &ex) }

      let!(:villa_inquiry) do
        create :villa_inquiry,
          currency: Currency::USD,
          external: external
      end

      let(:villa)       { villa_inquiry.villa }
      let(:villa_price) { villa.villa_price(Currency::USD) }
      let(:base_rate)   { villa_price.base_rate } # :base_rate gilt für 2 Personen
      let(:deposit)     { villa_price.deposit }
      let(:cleaning)    { villa_price.cleaning }

      shared_examples "clearing_items_usd" do
        it "includes clearing item in usd" do
          expect(clearing.rents).to all have_attributes price: have_attributes(currency: Currency::USD)
        end

        it { expect(clearing.rents).to include have_attributes(price: base_rate, category: "base_rate") }
      end

      include_examples "clearing_items_usd"

      it { expect(villa_price).to have_attributes(currency: "EUR", target_currency: "USD") }

      it { expect(base_rate).to eq 213 }
      it { expect(deposit).to eq 57 }
      it { expect(cleaning).to eq 57 }

      context "3 travelers" do
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

          it { expect(base_rate).to eq 249 }

          it "takes new exchange rate when editing booking" do
            clearing.update(Clearing::VillaParams.new.tap { |vp|
              vp.villa     = villa
              vp.travelers = villa_inquiry.travelers + [villa_inquiry.travelers.first.clone]
            }, villa_inquiry.inquiry)

            # Ursprünglicher Grundpreis bleibt erhalten, aktueller (mit aktuellem Umrechnungskurs) wird aber vorgeschlagen
            expect(clearing.rents).to include have_attributes(price: 213, normal_price: 249, category: "base_rate")
            # Es gab vorher nur 2 Reisende, daher ist diese Position neu und bekommt den Preis mit neuem Umrechnungskurs
            expect(clearing.rents).to include have_attributes(price: 63, category: "additional_adult")
          end

          it "takes new exchange rate for new booking" do
            new_clearing = Currency.with(Currency::USD) { create(:villa_inquiry, currency: Currency::USD) }.clearing

            # hier wird ein ClearingItem mit base_rate erzeugt, da es eine neue Anfrage ist
            expect(new_clearing.rents.first).to have_attributes(normal_price: 249, category: "base_rate")
          end
        end
      end

      context "external" do
        let(:external)         { true }
        let(:cc_fee_factor)    { 1 + (Setting.cc_fee_usd / 100) }

        def unfeed(price)
          price.unceiled / cc_fee_factor
        end

        it { expect(clearing.rents).to match [have_attributes(price: unfeed(base_rate), category: "base_rate")] }
        it { expect(clearing.deposits).to match [have_attributes(price: unfeed(deposit), category: "deposit")] }
        it { expect(clearing.cleaning).to eq unfeed(cleaning) }
      end
    end
  end

  context "Buchung mit einheitlichen Reisezeiträumen" do
    let!(:villa_inquiry) do
      villa_inquiry = create :villa_inquiry,
        start_date:        start_date,
        end_date:          end_date,
        external:          external,
        children_under_12: 2,
        adults:            3

      create :booking, inquiry: villa_inquiry.inquiry
      villa_inquiry
    end

    describe "Kalkulation" do
      it "enthält zwei Positionen für Erwachsene" do
        # - 1.1.-8.1. 2 Personen -> Grundpreis
        expect(clearing.rents).to include have_attributes(category: "base_rate", amount: 1, price: 160)
        expect(clearing.rents).to include have_attributes(category: "additional_adult", amount: 1, price: 40)
        expect(clearing.rents).not_to include have_attributes(category: "adults")
      end

      it "enthält eine Position für Kinder" do
        expect(clearing.rents).to include have_attributes(category: "children_under_12", amount: 2, price: 18)
      end

      context "high_season" do
        include_context "high season"

        delegate :villa, to: :villa_inquiry

        it "has high_season" do
          expect(villa.high_seasons).to be_present
          expect(villa_inquiry.discount_finder.high_season).to be_present
        end

        it "enthält eine Position für Grundpreis Hochsaison" do
          # - 1.1.-8.1. 2 Personen -> Grundpreis
          expect(clearing.rents).to include have_attributes(category: "base_rate_high_season", amount: 1, price: 32)
          expect(clearing.rents).to include have_attributes(category: "additional_adult_high_season", amount: 1, price: 8)
          expect(clearing.rents).not_to include have_attributes(category: "adults_high_season")
        end

        it "enthält eine Position für Kinder Hochsaison" do
          expect(villa_inquiry.travelers.where(price_category: "children_under_12").count).to eq 2
          expect(clearing.rents).to include have_attributes(category: "children_under_12_high_season", amount: 2, price: 3.6)
        end
      end
    end
  end
end
