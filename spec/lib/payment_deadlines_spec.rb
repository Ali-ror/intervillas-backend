require "rails_helper"

RSpec.describe PaymentDeadlines do
  subject { payment_deadlines }

  let(:booked_on)       { Date.current }
  let(:start_date)      { 40.days.from_now.to_date }
  let(:deposit)         { double "ClearingItem", price: Currency::Value.euro(1000) } # rubocop:disable RSpec/VerifiedDoubles
  let(:booking_total)   { Currency::Value.euro(3333) } # inkl. deposit
  let(:payments)        { [1, 2, 4, 8, 16, 32, 64, 173] } # 300
  let(:ack_downpayment) { false }
  let(:external)        { false }

  let(:inquiry) do
    # rubocop:disable RSpec/VerifiedDoubles
    double "Inquiry",
      external:        external,
      villa_inquiry:   double("VillaInquiry", start_date: start_date),
      booked_at:       booked_on,
      clearing:        double("Clearing", total: booking_total, deposits: [deposit]),
      payments:        payments.map { |val| double("Payment", paid_sum: val) },
      ack_downpayment: ack_downpayment,
      currency:        Currency::EUR
    # rubocop:enable RSpec/VerifiedDoubles
  end

  let(:payment_deadlines) { described_class.from_inquiry inquiry }

  # sanity checks
  its(:booked_on)  { is_expected.to eq booked_on }
  its(:start_date) { is_expected.to eq start_date }
  its(:total)      { is_expected.to eq booking_total }
  its(:payments)   { is_expected.to be_kind_of Array }
  its(:paid_total) { is_expected.to eq 300 }

  its(:difference)   { is_expected.to eq 3033 }
  its(:late?)        { is_expected.to be false }
  its(:overdues)     { is_expected.to be_empty }
  its(:due_balances) { is_expected.to eq 0 }
  its(:due_sum)      { is_expected.to eq 3033 }

  describe "Downpayment" do
    subject { payment_deadlines.downpayment_deadline }

    its(:ack)           { is_expected.to be ack_downpayment }
    its(:paid_sum)      { is_expected.to eq 300 }
    its(:date)          { is_expected.to eq booked_on + 7.days }
    its(:total_sum)     { is_expected.to eq(booking_total - deposit.price) }
    its(:allowed_delta) { is_expected.to be 10 } # aus Konstante
    its(:overdue?)      { is_expected.to be false }

    # 35% von 2333 (booking_total-deposit) auf den nächsten 10er aufgerundet
    its(:display_sum)  { is_expected.to eq 820 }
    its(:deadline_sum) { is_expected.to eq 820 }
    its(:due_balance)  { is_expected.to eq 520 } # paid_sum == 300
  end

  describe "Remainder" do
    subject { payment_deadlines.remainder_deadline }

    its(:ack)           { is_expected.to be ack_downpayment }
    its(:paid_sum)      { is_expected.to eq 300 }
    its(:date)          { is_expected.to eq start_date - 30.days }
    its(:total_sum)     { is_expected.to eq booking_total }
    its(:allowed_delta) { is_expected.to be 0 } # immer 0
    its(:overdue?)      { is_expected.to be false }

    # booking_total - downpament = 3333 - round10(0.35 * (3333 - 1000))
    its(:display_sum)  { is_expected.to eq 2513 }
    its(:deadline_sum) { is_expected.to eq booking_total }
    its(:due_balance)  { is_expected.to eq 3033 }
  end

  # Anzahlungen sind 7 Tage nach Buchung fällig
  context "downpayment overdue" do
    let(:booked_on) { 8.days.ago.to_date }

    its("overdues.size") { is_expected.to eq 1 }
    its(:due_balances)   { is_expected.to eq 520 }

    describe "Downpayment" do
      subject { payment_deadlines.downpayment_deadline }

      its(:overdue?) { is_expected.to be true }

      context "external booking" do
        let(:external) { true }

        its(:overdue?) { is_expected.to be false }
      end
    end

    describe "Remainder" do
      subject { payment_deadlines.remainder_deadline }

      its(:overdue?) { is_expected.to be false }
    end
  end

  context "downpayment and remainder overdue" do
    let(:booked_on)  { 40.days.ago.to_date }
    let(:start_date) { 10.days.from_now.to_date }

    its("overdues.size") { is_expected.to eq 2 }
    its(:due_balances)   { is_expected.to eq 3033 }

    describe "Downpayment" do
      subject { payment_deadlines.downpayment_deadline }

      its(:overdue?) { is_expected.to be true }

      context "external booking" do
        let(:external) { true }

        its(:overdue?) { is_expected.to be false }
      end
    end

    describe "Remainder" do
      subject { payment_deadlines.remainder_deadline }

      its(:overdue?) { is_expected.to be true }

      context "external booking" do
        let(:external) { true }

        its(:overdue?) { is_expected.to be false }
      end
    end
  end

  context "remainder overdue" do
    let(:booked_on)  { 40.days.ago.to_date }
    let(:start_date) { 10.days.from_now.to_date }
    let(:payments)   { [1170] }

    its("overdues.size") { is_expected.to eq 1 }
    its(:due_balances)   { is_expected.to eq 2163 }

    describe "Downpayment" do
      subject { payment_deadlines.downpayment_deadline }

      its(:overdue?) { is_expected.to be false }
    end

    describe "Remainder" do
      subject { payment_deadlines.remainder_deadline }

      its(:overdue?) { is_expected.to be true }

      context "external booking" do
        let(:external) { true }

        its(:overdue?) { is_expected.to be false }
      end
    end
  end

  context "late and overdue" do # late implies overdue
    let(:start_date) { (booked_on + 28.days).to_date }

    its(:late?)                { is_expected.to be true }
    its(:downpayment_deadline) { is_expected.to be_nil }
    its("overdues.size")       { is_expected.to eq 1 }
    its(:due_balances)         { is_expected.to eq 3033 }

    describe "Downpayment" do
      subject { payment_deadlines.downpayment_deadline }

      it { is_expected.to be_nil }
    end

    describe "Remainder" do
      subject { payment_deadlines.remainder_deadline }

      its(:overdue?) { is_expected.to be true }
      its(:date)     { is_expected.to eq booked_on } # max(start_date - 30d, booked_on)

      context "external booking" do
        let(:external) { true }

        its(:overdue?) { is_expected.to be false }
      end
    end
  end

  describe "#late?" do
    # Ref #432
    # Buchungen mit Reiseantritt in weniger als 31 Tagen und mit Fälligkeit der
    # Restzahlung vor der Anzahlung gelten als kurzfristig. Also im Endeffekt
    # Buchungen mit Reiseantritt in weniger als 38 Tagen, da die Anzahlung
    # in 7 Tagen fällig wird.

    context "at start_date" do
      let(:start_date) { booked_on }

      its(:late?) { is_expected.to be true }
    end

    context "31 Days before" do
      let(:start_date) { (booked_on + 31.days).to_date }

      its(:late?) { is_expected.to be true }
    end

    context "38 Days before" do
      let(:start_date) { (booked_on + 38.days).to_date }

      its(:late?) { is_expected.to be true }

      describe ".downpayment_deadline" do
        subject(:downpayment) { payment_deadlines.downpayment_deadline }

        it { is_expected.to be_nil }
      end

      describe ".remainder_deadline" do
        subject(:remainder) { payment_deadlines.remainder_deadline }

        its(:date)         { is_expected.to eq booked_on }
        its(:deadline_sum) { is_expected.to eq payment_deadlines.total }
      end
    end

    context "39 Days before" do
      let(:start_date) { (booked_on + 39.days).to_date }

      its(:late?) { is_expected.to be false }

      describe ".downpayment_deadline" do
        subject(:downpayment) { payment_deadlines.downpayment_deadline }

        its(:date) { is_expected.to eq (booked_on + 7.days).to_date }
      end

      describe ".remainder_deadline" do
        subject(:remainder) { payment_deadlines.remainder_deadline }

        its(:date) { is_expected.to eq (start_date - 30.days).to_date }
      end
    end
  end

  describe "#downpayment_percentage" do
    let(:changed_on) { PaymentDeadlines::DOWNPAYMENT_PERCENTAGE_CHANGED_ON }

    context "booking before change" do
      let(:booked_on)  { changed_on - 6.months }
      let(:start_date) { changed_on - 1.day }

      its(:downpayment_percentage) { is_expected.to eq 0.2 }
    end

    context "booking on or after change" do
      let(:booked_on)  { changed_on }
      let(:start_date) { changed_on + 40.days }

      its(:downpayment_percentage) { is_expected.to eq 0.35 }
    end

    context "booking during change" do
      let(:booked_on)  { changed_on - 2.months }
      let(:start_date) { changed_on + 2.months }

      its(:downpayment_percentage) { is_expected.to eq 0.2 }
    end
  end
end
