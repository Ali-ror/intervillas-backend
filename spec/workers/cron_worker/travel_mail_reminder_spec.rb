require "rails_helper"

RSpec.describe CronWorker::TravelMailReminder, sidekiq: :inline do
  let(:payment) { false }
  let!(:booking)              { create_full_booking start_date: 2.weeks.from_now }
  let!(:external_booking)     { create :booking, :external, start_date: 2.weeks.from_now }
  let!(:external_booking_far) { create :booking, :external, start_date: 1.year.from_now }

  before do
    if payment
      create :payment,
        inquiry: booking.inquiry,
        sum:     booking.clearing.total,
        paid_on: Date.current
    end

    described_class.perform_async

    booking.reload
    external_booking.reload
    external_booking_far.reload
  end

  # unpaid booking
  it { expect(booking.travel_mail).to be_nil }

  # Externe Buchungen haben keine Zahlungen
  it { expect(external_booking.travel_mail).not_to be_nil }

  # Weit entfernte Buchung soll noch nicht versendet werden
  it { expect(external_booking_far.travel_mail).to be_nil }

  context "with paid booking" do
    let(:payment) { true }

    it { expect(booking.travel_mail).not_to be_nil }
    it { expect(booking.travel_mail.sent_at).not_to be_nil }
  end
end
