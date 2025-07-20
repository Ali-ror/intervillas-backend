require "rails_helper"

RSpec.describe VillaBilling do
  it { is_expected.to belong_to(:owner).class_name("Contact") }

  # TODO: warum kommentiert?
  #
  # context "a new billing" do
  #   let(:villa_inquiry) { create_full_booking(with_owner: true).villa_inquiry }
  #   let(:villa) { villa_inquiry.villa }
  #
  #   it "takes owner from villa" do
  #     billing = villa_inquiry.create_billing!
  #     expect(billing.owner).to eq villa.owner
  #   end
  # end

  context "prepared billing" do
    subject(:villa_billing) { inquiry.villa_billings.first }

    include_context "prepare billings"

    let(:eps) { 0.001 }

    shared_examples "taxed calculations" do |year, values|
      let(:commission_factor) { values["commission"] / 100.0 }
      let(:gross_total)       { values["rent.gross"] + values["cleaning.gross"] + values["energy.gross"] }

      around do |ex|
        Timecop.travel Date.current.strftime("#{year}-%m-%d").to_date, &ex
      end

      it "calculates rent" do # rubocop:disable RSpec/MultipleExpectations
        rent = villa_billing.rent
        expect(rent).to be_kind_of Billing::Position

        a, b = year < 2019 ? %i[sales sales_2019] : %i[sales_2019 sales]
        expect(rent.gross).to be_within(eps).of values["rent.gross"]
        expect(rent.net).to be_within(eps).of values["rent.net"]
        expect(rent.proportions[a]).to be_within(eps).of values["rent.prop.sales"]
        expect(rent.proportions[b]).to be_nil
        expect(rent.proportions[:tourist]).to be_within(eps).of values["rent.prop.tourist"]
      end

      it "calculates cleaning" do
        cleaning = villa_billing.cleaning
        expect(cleaning).to be_kind_of Billing::Position

        a, b = year < 2019 ? %i[cleaning cleaning_2019] : %i[cleaning_2019 cleaning]
        expect(cleaning.gross).to be_within(eps).of values["cleaning.gross"]
        expect(cleaning.proportions[a]).to be_within(eps).of values["cleaning.prop.cleaning"]
        expect(cleaning.proportions[b]).to be_nil
      end

      it "calculates energy" do
        energy = villa_billing.energy
        expect(energy).to be_kind_of Billing::Position

        a, b = year < 2019 ? %i[energy energy_2019] : %i[energy_2019 energy]
        expect(energy.gross).to be_within(eps).of values["energy.gross"]
        expect(energy.proportions[a]).to be_within(eps).of values["energy.prop.energy"]
        expect(energy.proportions[b]).to be_nil
      end

      it "calculates positions" do
        pos = villa_billing.positions
        expect(pos).to be_kind_of Array
        expect(pos).to all be_kind_of Billing::Position

        expect(pos.map(&:gross).sum).to be_within(eps).of gross_total
      end

      its("total.gross")      { is_expected.to be_within(eps).of gross_total }
      its(:commission)        { is_expected.to eq values["commission"] }
      its(:agency_commission) { is_expected.to be_within(eps).of values["rent.net"] * commission_factor }

      describe "60:40 rule" do
        let(:boat_optional) { false }
        let(:boat_owner) { villa_owner }

        its(:boat_inquiry)      { is_expected.to be_present }
        its("rent.gross")       { is_expected.to be_within(eps).of values["rent.gross"] * 0.6 }
        its("rent.net")         { is_expected.to be_within(eps).of values["rent.net"] * 0.6 }
        its("total.gross")      { is_expected.to be_within(eps).of (values["rent.gross"] * 0.6) + values["cleaning.gross"] + values["energy.gross"] }
        its(:agency_commission) { is_expected.to be_within(eps).of values["rent.net"] * 0.6 * (values["commission"] / 100.0) }
      end
    end

    context "before 2019" do # 6% sales tax
      include_examples "taxed calculations", 2016,
        "rent.gross"             => 1120,
        "rent.net"               => 1009.00900901,
        "rent.prop.sales"        => 60.54,
        "rent.prop.tourist"      => 50.45,
        "cleaning.gross"         => 42.42,
        "cleaning.prop.cleaning" => 4.204,
        "energy.gross"           => 149,
        "energy.prop.energy"     => 14.766,
        "commission"             => 20
    end

    context "after 2019" do # 6.5% sales tax
      include_examples "taxed calculations", 2019,
        "rent.gross"             => 1120,
        "rent.net"               => 1004.48430493,
        "rent.prop.sales"        => 65.2912,
        "rent.prop.tourist"      => 50.224,
        "cleaning.gross"         => 42.42,
        "cleaning.prop.cleaning" => 4.375,
        "energy.gross"           => 149,
        "energy.prop.energy"     => 15.368,
        "commission"             => 20
    end
  end

  context "villa_billing" do
    let(:booking) { create_full_booking with_owner: true }
    let(:villa_billing) { booking.villa_inquiry.build_billing }
    let(:owner) { booking.villa.owner }

    describe "#agency_fee" do
      context "default" do
        it do
          expect(villa_billing.agency_fee).to eq 15.0
        end
      end

      context "overridden by owner" do
        before do
          owner.agency_fee = 20.0
          owner.save!
        end

        it { expect(villa_billing.agency_fee).to eq 20.0 }
      end
    end

    # Gebühr für Haustiere und spätem Checkout verhalten sich gleich
    %w[pet_fee late_checkout].each do |category|
      describe category do
        before do
          create :clearing_item,
            inquiry_id: booking.inquiry_id,
            category:,
            villa_id:   booking.villa.id,
            price:      120
        end

        let(:fee_value) { villa_billing.send(category) }

        it { expect(fee_value).to have_attributes gross: 120, net: be_within(0.01).of(107.62) }
        it { expect(villa_billing.positions).to include have_attributes subject: category.to_sym }

        # Gebühr soll in Provision berücksichtigt werden
        it { expect(villa_billing.agency_commission).to eq (villa_billing.rent.net + fee_value.net) * villa_billing.commission / 100 }
      end
    end

    describe "pet_fee + early_checkin + late_checkout" do
      before do
        create :clearing_item,
          inquiry_id: booking.inquiry_id,
          category:   "pet_fee",
          villa_id:   booking.villa.id,
          price:      20

        create :clearing_item,
          inquiry_id: booking.inquiry_id,
          category:   "early_checkin",
          villa_id:   booking.villa.id,
          price:      42

        create :clearing_item,
          inquiry_id: booking.inquiry_id,
          category:   "late_checkout",
          villa_id:   booking.villa.id,
          price:      100
      end

      let(:expected_agency_commission) do
        rent = %i[rent pet_fee early_checkin late_checkout].map { |cat| villa_billing.send(cat).net }.sum
        rent * villa_billing.commission / 100
      end

      it { expect(villa_billing.pet_fee).to have_attributes gross: 20, net: be_within(0.01).of(17.94) }
      it { expect(villa_billing.early_checkin).to have_attributes gross: 42, net: be_within(0.01).of(37.67) }
      it { expect(villa_billing.late_checkout).to have_attributes gross: 100, net: be_within(0.01).of(89.69) }
      it { expect(villa_billing.agency_commission).to eq expected_agency_commission }
    end

    describe "Tenant PDF" do
      let(:tenant_pdf)   { booking.to_billing.tenant_billing.pdf }
      let(:pdf_file)     { tenant_pdf.save(force: true) }
      let(:pdf) {
        PDF::Reader.new(pdf_file).pages.flat_map { |page|
          page.text.unicode_normalize(:nfc).gsub(/\n\n+/, "\n").lines.map(&:squish)
        }.join("\n")
      }

      let(:customer_attributes) do
        {
          bank_name:           "Knauser Kasse",
          bank_account_owner:  "Gustav Gans",
          bank_account_number: "KNAUSXXX000",
          bank_code:           "DE00000000000000000001",
        }
      end

      before do
        # avoid xmas and easter holidays
        travel_to Date.current.change(month: 8, day: 15)

        booking.customer.update!(**customer_attributes)
        booking.villa_inquiry.create_billing!(
          energy_pricing:      :usage,
          meter_reading_begin: 1000,
          meter_reading_end:   1200,
        )
      end

      it "renders contents" do
        [
          "Kaution Villa (#{booking.villa.admin_display_name}) 42,42",
          "Kaution Total 42,42",
          "Zählerstand Beginn 1000,00 kWh",
          "Zählerstand Ende 1200,00 kWh",
          "Verbrauch 200,00 kWh",
          "Energiekosten (Verbrauch × EUR 0,14 pro kWh) 28,00",
          "Rückzahlung (Kaution – Kosten) 14,42",
          "Konto-Inhaber Gustav Gans",
          "Name der Bank Knauser Kasse",
          "BIC (SWIFT) KNAUSXXX000",
          "IBAN DE00000000000000000001",
        ].each do |line|
          expect(pdf).to include line
        end
      end

      context "with legacy bank account information" do
        let(:customer_attributes) do
          {
            bank_name:           "Zins & Zins OHG",
            bank_account_owner:  "Richard Reich",
            bank_account_number: "1234567890",
            bank_code:           "99999999",
          }
        end

        it "renders contents" do
          [
            "Konto-Inhaber Richard Reich",
            "Name der Bank Zins & Zins OHG",
            "Konto-Nr. 1234567890",
            "BLZ 99999999",
          ].each do |line|
            expect(pdf).to include line
          end
        end
      end
    end
  end
end
