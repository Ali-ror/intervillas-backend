require "rails_helper"

RSpec.describe MyBookingPal::Reservation::Payload do
  subject(:payload) { described_class.new(payload_data) }

  # the booking simuated here has the following surcharges:
  #
  # - high season from 2024-12-01 til 2024-12-06
  # - no surchage on   2024-12-07 and 2024-12-08
  # - christmas   from 2024-12-09 til 2024-12-12

  let(:start_date)     { "2024-12-01".to_date }
  let(:end_date)       { "2024-12-12".to_date }
  let(:length_of_stay) { (end_date - start_date).to_i } # 11 days

  let(:tax_factor)     { 1.115 } # 11.5% taxes
  let(:mbp_markup)     { (100 + villa.additional_properties_with_defaults.dig(:los, :surcharge)) / 100.to_d }
  let(:num_people)     { 4 }

  let(:base_rate)  { prices.calculate_base_rate(occupancy: num_people).to_d * mbp_markup }
  let(:rent_net)   { base_rate * length_of_stay }
  let(:rent_gross) { rent_net * tax_factor }
  let(:commission) { ((rent_net + cleaning) * 0.15).round(2) } # 15%

  let(:prices)   { villa.villa_price(Currency::USD) }
  let(:deposit)  { prices.deposit.to_d }
  let(:cleaning) { prices.cleaning.to_d }

  let(:payload_data) do
    {
      "reservationId" => "666",
      "channelName"   => "TEST",
      "fromDate"      => start_date.to_s,
      "toDate"        => end_date.to_s,
      "total"         => (rent_gross + cleaning + deposit).round(2),
      "adult"         => num_people,
      "child"         => 0,
      "commission"    => {
        "channelCommission" => commission,
        "commission"        => 0.0,
      },
      "fees"          => [
        { "id" => "house_deposit", "name" => "Deposit",  "value" => deposit.to_f },
        { "id" => "cleaning",      "name" => "Cleaning", "value" => cleaning.to_f },
      ],
      "rate"          => {
        "netRate"              => rent_net.to_f,
        "originalRackRate"     => rent_net.to_f,
        "newPublishedRackRate" => rent_net.to_f,
      },
    }
  end

  let(:villa) do
    create(:villa, :bookable).tap { |v|
      create :high_season,
        starts_on: "2024-11-01".to_date,
        ends_on:   "2024-12-06".to_date,
        villas:    [v],
        addition:  50

      # xmas is on 25th, we want to start the xmas surcharge on the 9th
      create :holiday_discount, :christmas,
        days_before: ("2024-12-25".to_date - "2024-12-09".to_date).to_i,
        days_after:  7,
        percent:     25,
        villa:       v

      create :villa_price,
        villa:    v,
        currency: Currency::USD
    }
  end

  describe "#clearing_item_params" do
    subject(:clearing_items) { payload.to_clearing_item_params(villa) }

    def a_clearing_item(dates: true, **rest)
      tpl = { villa_id: villa.id, amount: 1, **rest }
      if dates
        tpl[:start_date] = start_date
        tpl[:end_date]   = end_date
      end

      a_hash_including(**tpl)
    end

    let(:handling_item) {
      a_clearing_item(
        dates:    false,
        category: "handling",
        price:    commission,
        villa_id: nil,
        note:     "TEST via BookingPal #666",
      )
    }

    let(:deposit_item) {
      a_clearing_item(
        dates:    false,
        category: "deposit",
        price:    within(0.001).of(deposit),
      )
    }

    let(:cleaning_item) {
      a_clearing_item(
        dates:    false,
        category: "cleaning",
        price:    within(0.001).of(cleaning),
      )
    }

    let(:base_rate_item) {
      a_hash_including(
        category:       "base_rate_booking_pal",
        price:          ((rent_gross - commission) / length_of_stay).round(2),
        minimum_people: num_people,
      )
    }

    # uncomment for debugging of single items
    # it { is_expected.to include handling_item }
    # it { is_expected.to include cleaning_item }
    # it { is_expected.to include deposit_item }
    # it { is_expected.to include base_rate_item }

    it { is_expected.to contain_exactly(handling_item, cleaning_item, deposit_item, base_rate_item) }
  end
end
