require "rails_helper"

RSpec.describe Api::MyBookingPal::ReservationsController do
  let(:reservation_id) { rand 21_000_000..21_999_999 }
  let(:villa)          { create :villa, :bookable }
  let(:product)        { create(:booking_pal_product, villa:) }

  def post_reservation(action, **params)
    {
      "action"                         => action,
      "reservationNotificationRequest" => build_payload(**params),
    }.tap do |payload|
      post :create, as: :json, body: payload.to_json
    end
  end

  def build_payload(start_date:, end_date:, adults: 2, notes: nil)
    # values/calculations taken from spec/lib/my_booking_pal/reservation/payload_spec.rb
    length_of_stay = (end_date.to_date - start_date.to_date).to_i
    mbp_markup     = (100 + product.villa.additional_properties_with_defaults.dig(:los, :surcharge)) / 100.to_d
    prices         = villa.villa_price(Currency::USD)
    deposit        = prices.deposit.to_d
    cleaning       = prices.cleaning.to_d
    base_rate      = prices.calculate_base_rate(occupancy: adults).to_d * mbp_markup
    rent_net       = base_rate * length_of_stay
    rent_gross     = rent_net * 1.115 # 11.5% taxes
    commission     = ((rent_net + cleaning) * 0.15).round(2) # 15%

    {
      "reservationId" => reservation_id,
      "productId"     => product.foreign_id,
      "channelName"   => "TEST",
      "customerName"  => "DOE, JOHN",
      "fromDate"      => start_date.to_date.to_s,
      "toDate"        => end_date.to_date.to_s,
      "adult"         => adults,
      "child"         => 0,
      "email"         => "john.doe@example.com",
      "total"         => (rent_gross + cleaning + deposit).round(2).to_f,
      "fees"          => [
        { "id" => "house_deposit", "name" => "Deposit", "value" => deposit.to_f },
        { "id" => "cleaning", "name" => "Cleaning", "value" => cleaning.to_f },
      ],
      "commission"    => {
        "channelCommission" => commission.to_f,
        "commission"        => 0,
      },
      "rate"          => {
        "original"             => rent_net.to_f,
        "netRate"              => rent_net.to_f,
        "newPublishedRackRate" => rent_net.to_f,
      },
      "notes"         => notes,
    }
  end

  def expect_error_details(details)
    code        = response.parsed_body.fetch("code")
    raw_details = Sidekiq.redis { _1.get "mybookingpal:reservationerrors:#{code}" }
    expect(JSON.parse(raw_details)).to include(details)
  end

  it "rejects empty payloads" do
    post :create, body: "{}", as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to include(
      "is_error" => true,
      "message"  => "Reservation request could not be processed",
    )

    expect_error_details(
      "class"   => "ActionController::ParameterMissing",
      "message" => "param is missing or the value is empty: reservationNotificationRequest",
      "payload" => {},
    )
  end

  it "rejects requests without body" do
    post :create, body: nil, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to include(
      "is_error" => true,
      "message"  => "Reservation request could not be processed",
    )

    expect_error_details(
      "class"   => "ActionController::ParameterMissing",
      "message" => "param is missing or the value is empty: reservationNotificationRequest",
      "payload" => {},
    )
  end

  it "rejects unknown actions" do
    payload = post_reservation "snafu",
      start_date: 4.days.from_now,
      end_date:   5.days.from_now

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to include(
      "is_error" => true,
      "message"  => "Reservation request could not be processed",
    )
    expect_error_details(
      "class"   => "Api::MyBookingPal::ReservationsController::UnknownAction",
      "message" => "unknown action: snafu",
      "payload" => payload,
    )
  end

  context "with unknown reservations" do
    it "updates fail" do
      payload = post_reservation "update",
        start_date: 42.days.from_now,
        end_date:   (42 + 15).days.from_now

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include(
        "is_error" => true,
        "message"  => "Reservation could not be placed: unit not available",
      )
      expect_error_details(
        "class"   => "ActiveRecord::RecordNotFound",
        "message" => match(/^Couldn't find MyBookingPal::Reservation::Create/),
        "payload" => payload,
      )
    end

    it "cancellations fail" do
      payload = post_reservation "cancel",
        start_date: 42.days.from_now,
        end_date:   (42 + 15).days.from_now

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to include(
        "is_error" => true,
        "message"  => "Reservation could not be placed: unit not available",
      )
      expect_error_details(
        "class"   => "ActiveRecord::RecordNotFound",
        "message" => match(/^Couldn't find MyBookingPal::Reservation::Create/),
        "payload" => payload,
      )
    end
  end

  it "rejects reservation requests" do
    payload = post_reservation "reservation_request",
      start_date: 4.days.from_now,
      end_date:   5.days.from_now

    expect(response).to have_http_status(:internal_server_error)
    expect(response.parsed_body).to include(
      "is_error" => true,
      "message"  => "Request action type is not supported",
    )
    expect_error_details(
      "class"   => "Api::MyBookingPal::ReservationsController::UnsupportedAction",
      "message" => "action reservation_request is not supported",
      "payload" => payload,
    )
  end

  it "creates a new booking" do
    post_reservation "create",
      start_date: 42.days.from_now,
      end_date:   (42 + 15).days.from_now

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "is_error" => false,
      "message"  => "Booking reservation was created successfully",
    )

    inq = Inquiry.find response.parsed_body.fetch("altId").sub(/^IV-E/, "")
    expect(inq).to have_attributes(
      external: true,
      comment:  "TEST via BookingPal ##{reservation_id}",
    )
    expect(inq).to be_booked
  end

  context "with existing reservation" do
    let(:start_date) { (42 - 7).days.from_now.to_date }
    let(:end_date)   { (42 - 7 + 15).days.from_now.to_date }

    let!(:reservation) {
      MyBookingPal::Reservation::Create.create_from_payload!(
        build_payload(start_date:, end_date:, notes: "note from existing reservation"),
      )
    }

    let(:inquiry) { reservation.inquiry }

    it "booking can be updated" do
      # different date range
      new_start_date = start_date + 7.days
      new_end_date   = end_date + 7.days

      # ensure the test is deterministic: when %s >= 58, the update message
      # might contain a different minute value
      now = Time.current
      travel_to now.change(sec: 0)

      post_reservation "update",
        start_date: new_start_date,
        end_date:   new_end_date,
        notes:      "this is a note from the update"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "altId"    => inquiry.number,
        "is_error" => false,
        "message"  => "Booking reservation was updated successfully",
      )

      expect {
        inquiry.reload
      }.to change(inquiry, :start_date).from(start_date).to(new_start_date)
        .and change(inquiry, :end_date).from(end_date).to(new_end_date)

      expect(inquiry.comment.lines(chomp: true)).to eq [
        "TEST via BookingPal ##{reservation_id}",
        "",
        "note from existing reservation",
        "",
        now.strftime("Update %Y/%m/%d %H:%M:"),
        "this is a note from the update",
      ]
    end

    it "booking can be cancelled" do
      post_reservation("cancel", start_date:, end_date:)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "altId"    => inquiry.number,
        "is_error" => false,
        "message"  => "Booking reservation was cancelled successfully",
      )

      expect {
        inquiry.reload
      }.to change(inquiry, :booked?).to(false)
        .and change(inquiry, :cancelled?).to(true)
    end
  end
end
