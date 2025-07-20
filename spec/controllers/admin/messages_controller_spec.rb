require "rails_helper"

RSpec.describe Admin::MessagesController do
  include_context "as_admin"

  let(:booking) { create_full_booking with_owner: true }

  let(:message_params) {
    {
      text: "foobar foo",
      type: "owner",
    }
  }

  before do
    # damit `redirect_to :back` funktioniert
    request.env["HTTP_REFERER"] = edit_admin_booking_url(booking)
  end

  describe "#create for Booking messages" do
    context "valid" do
      it "creates a message" do
        expect {
          post :create, params: { inquiry_id: booking.id, message: message_params }
          is_expected.to respond_with :redirect
        }.to change(Message, :count).by(1)
      end
    end

    context "boat_owner message for booking with optional boat" do
      let(:booking) { create_full_booking_with_boat with_owner: true, boat_state: :optional }

      let(:message_params) {
        {
          text: "foobar foo",
          type: "boat_owner",
        }
      }

      it "creates a message to boat_owner" do
        expect {
          post :create, params: { inquiry_id: booking.id, message: message_params }
          is_expected.to respond_with :redirect

          expect(Message.last.recipient).to eq booking.boat.owner
        }.to change(Message, :count).by(1)
      end
    end
  end
end
