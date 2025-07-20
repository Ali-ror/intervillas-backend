require "rails_helper"

RSpec.describe CronWorker::InquiryReminder, sidekiq: :inline do
  let(:inquiry) { create_villa_inquiry.inquiry }

  it "reminds customers off pending inquiries" do
    expect(inquiry.reminded_on).to be_nil
    inquiry.update! created_at: 5.days.ago
    allow(MailWorker).to receive(:perform_async).and_call_original

    described_class.perform_async

    expect(MailWorker).to have_received(:perform_async)
      .with("Message", Message.last.id, "deliver!")

    expect(inquiry.reload.reminded_on).not_to be_nil
  end
end
