require "rails_helper"

RSpec.feature "Buchung in USD (für Amerikaner)", :js do
  let(:customer_params) { attributes_for :customer }

  def create_booking_or_reservation
    expect(other_inquiry.start_date).to eq inquiry.start_date
    expect(other_inquiry.end_date).to eq inquiry.end_date

    visit new_booking_path(token: inquiry.token)

    if admin.present?
      confirm_booking_request_on_page inquiry, customer_params:, button_text: "Jetzt buchen"
      expect(page).to have_content "Vielen Dank für Ihre Buchung"
    else
      confirm_booking_request_on_page inquiry, customer_params:, button_text: "weiter zur Zahlung"
      expect(page).to have_content "Zahlungsübersicht"
    end

    inquiry.reload
    yield

    inquiry.reload
    expect(inquiry.reservation).not_to be_present
    expect(inquiry.booking).to be_present
  end

  shared_examples "erfordert keine Zahlung" do
    it "erfordert Zahlung", :vcr do
      create_booking_or_reservation do
        expect(page).to have_content "Vielen Dank für Ihre Buchung und Ihr Vertrauen!"
      end
    end
  end

  shared_examples "erfordert Zahlung" do
    it "erfordert Zahlung", :vcr do
      create_booking_or_reservation do
        # Haus ist jetzt reserviert
        expect(inquiry.reservation).to be_present
        expect(inquiry.booking).not_to be_present

        # in zweiter Session versuchen das Haus zu buchen (-> sollte vorübergehend nicht möglich sein)
        using_ephemeral_session "another customer" do
          visit new_booking_path(token: other_inquiry.token)

          within ".alert-warning" do
            expect(page).to have_content "Dieses Haus ist vorübergehend für einen anderen Kunden reserviert. Bitte versuchen Sie es in etwa 30 Minuten erneut."
          end
          expect(page).to have_button "weiter zur Zahlung", disabled: true

          click_on "Sprache wechseln"
          click_on "Englisch"
          within ".alert-warning" do
            expect(page).to have_content "This house is temporarily reserved for another customer. Please try again in about 30 minutes."
          end
          expect(page).to have_button "continue with payment", disabled: true
        end

        expect(page).to have_current_path payments_path(inquiry.token), ignore_query: true

        expect(page).to have_content case provider
        when :bsp1   then "Bequem und sicher mit Kreditkarte bezahlen."
        when :paypal then "Bequem und sicher mit PayPal bezahlen."
        else raise ArgumentError, "unexpected provider: #{provider.inspect}"
        end

        fake_payment(provider, inquiry.reservation)

        expect(page).to have_content "Vielen Dank für Ihre Buchung und Ihr Vertrauen!", wait: 5
      end
    end
  end

  shared_examples "less than 40 days in the future" do
    let(:admin)          { nil }
    let(:inquiry_params) { { currency: Currency::USD, start_date: 20.days.from_now.to_date } }

    let(:inquiry)       { create_villa_inquiry(**inquiry_params).inquiry }
    let(:other_inquiry) { create_villa_inquiry(villa: inquiry.villa, **inquiry_params).inquiry }

    include_examples "erfordert Zahlung"

    context "as admin" do
      include_context "as_admin"
      include_examples "erfordert keine Zahlung"
    end
  end

  shared_examples "more than 40 days in the future" do
    let(:inquiry) { create_villa_inquiry(currency: Currency::USD).inquiry }

    it "no payment required" do
      visit new_booking_path(token: inquiry.token)

      expect(page).to have_button "Jetzt buchen"
      confirm_booking_request_on_page(inquiry, customer_params:)
      expect(page).to have_content "Vielen Dank für Ihre Buchung"

      # Haus ist jetzt reserviert
      inquiry.reload
      expect(inquiry.booking).to be_present
    end
  end

  context "gmbh" do
    travel_to_gmbh_era! offset: rand(1..14).days

    it_behaves_like "more than 40 days in the future"
    it_behaves_like "less than 40 days in the future" do
      let(:provider) { :paypal }
    end
  end

  context "corp" do
    travel_to_corp_era! offset: rand(1..14).days

    it_behaves_like "more than 40 days in the future"
    it_behaves_like "less than 40 days in the future" do
      let(:provider) { :paypal }
    end
  end
end
