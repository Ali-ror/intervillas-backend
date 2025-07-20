require "rails_helper"

RSpec.describe CronWorker::PaymentPrenotification, sidekiq: :inline do
  # "Restzahlung 30 Tage vor Reiseantritt" plus plus 5-7-Tage-Fenster
  # in Bookings::Communication.for_payment_prenotification
  let(:prenotification_window) { 30.days.from_now + 6.days }
  let!(:booking) { create_full_booking start_date: prenotification_window }

  def message_count
    Message
      .template("payment_prenotification")
      .where(inquiry_id: booking.inquiry_id)
      .count
  end

  it "delivers it once" do
    expect {
      described_class.perform_async
      described_class.perform_async
    }.to change { message_count }.by(1)
  end

  it "doesn't delivers it twice" do
    described_class.perform_async
    expect {
      described_class.perform_async
    }.not_to(change { message_count })
  end
end
