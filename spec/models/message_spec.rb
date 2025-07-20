require "rails_helper"

RSpec.describe Message do
  it { is_expected.to belong_to :recipient }
  it { is_expected.to belong_to :inquiry }

  it { is_expected.to validate_presence_of :recipient }
  it { is_expected.to validate_presence_of :inquiry }

  context "a Message", sidekiq: :inline, vcr: true do
    subject(:message) { Message.new(message_params) }

    let(:booking) { create_full_booking }
    let(:villa) { booking.villa }

    context "to Property Management" do
      let(:manager) { create :contact }
      let(:message_params) {
        attributes_for :manager_message,
          inquiry_id:     booking.inquiry_id,
          recipient_id:   manager.id,
          recipient_type: manager.class.name
      }

      before do
        villa.manager = manager
        allow(villa).to receive :attach_geocode
        villa.save!
      end

      it do
        expect(message).to be_valid
        expect { message.save }.not_to raise_error
      end

      it do
        message.save
        expect(message).to have_sent_message
      end
    end

    matcher :have_sent_message do
      match do |actual|
        actual.reload.sent_at?
      end
    end

    context "to Owner" do
      let(:owner) { create :contact }
      let(:message_params) {
        attributes_for :owner_message,
          inquiry_id:     booking.inquiry_id,
          recipient_id:   owner.id,
          recipient_type: owner.class.name
      }

      before do
        villa.owner = owner
        allow(villa).to receive :attach_geocode
        villa.save!
      end

      it do
        message.save
        expect(message).to have_sent_message
      end
    end
  end
end
