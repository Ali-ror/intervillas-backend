require "rails_helper"

RSpec.describe BookingsController do
  render_views

  describe "Given a Villa" do
    let(:villa_inquiry) { create_villa_inquiry }
    let(:inquiry) { villa_inquiry.inquiry }
    let(:villa) { villa_inquiry.villa }

    describe "on GET to :new" do
      before do
        get :new, params: { token: inquiry.token, villa_id: villa.to_param }
      end

      it { is_expected.to respond_with :success }
      it { is_expected.to render_template(:new) }
    end

    describe "#redirect_new" do
      before do
        get :redirect_new, params: { villa_id: villa.to_param, token: "token" }
      end

      it { is_expected.to redirect_to "/inquiries/token/book" }
    end

    describe "#create" do
      let(:booking_params) do
        {
          "customer_attributes"  => {
            "address"             => "Jillianstr. 48",
            "appnr"               => "843",
            "postal_code"         => "74077",
            "city"                => "Gruenhain-Beierfeld",
            "country"             => "DE",
            "state_code"          => "BW",
            "bank_account_owner"  => "",
            "bank_account_number" => "",
            "bank_name"           => "",
            "bank_code"           => "",
            "travel_insurance"    => "insured",
          },
          "travelers_attributes" => {
            "0" => {
              "first_name" => "Kylie",
              "last_name"  => "Watsica",
              "born_on"    => "1980-07-01",
            },
            "1" => {
              "first_name" => "Kylie",
              "last_name"  => "Watsica",
              "born_on"    => "1980-07-01",
            },
          },
          "agb"                  => "1",
        }
      end

      context "valid" do
        before do
          post :create, params: { villa_id: villa.to_param, token: inquiry.token, booking: booking_params }
        end

        it { is_expected.to redirect_to "/inquiries/processing" }
      end

      context "invalid" do
        before do
          allow_any_instance_of(BookingForms::Customer).to receive(:process).and_return(false)
          post :create, params: { villa_id: villa.to_param, token: inquiry.token, booking: { foo: :bar } }
        end

        it { expect(inquiry).to be_timely }

        it { is_expected.to respond_with :unprocessable_entity }
        it { is_expected.to render_template :new }
      end
    end
  end

  context "Given a Booking" do
    let(:villa) { booking.villa }
    let(:inquiry) { booking.inquiry }

    %w[de en].each do |locale|
      [true, false].each do |with_boat|
        describe "#confirmation locale: #{locale}, with_boat: #{with_boat.inspect}" do
          let(:booking) { with_boat ? create_full_booking_with_boat : create_full_booking }

          before do
            get :confirmation, params: { token: inquiry.reload.token, locale: }
          end

          it { is_expected.to respond_with :success }
        end
      end
    end
  end
end
