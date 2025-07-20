require "rails_helper"

RSpec.describe CronWorker::CollectReviews, sidekiq: :inline do
  subject(:inquiry) { booking.inquiry }

  let(:booking) { create_full_booking end_date: 10.days.ago }

  def perform!
    expect(inquiry).not_to be_nil

    described_class.perform_async

    inquiry.reload
  end

  it "prepares a review" do
    expect { perform! }.to change(inquiry, :review).from(nil)
  end

  it "sends a mail to the customer" do
    perform!

    expect(inquiry.review.message).not_to be_nil
    expect(inquiry.review.message.sent_at).not_to be_nil
  end
end
