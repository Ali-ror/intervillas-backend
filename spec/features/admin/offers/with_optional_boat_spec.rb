require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "mit Boot" do
    feature "mit Boot" do
      let!(:villa) { create :villa, :with_optional_boat, :bookable }

      before do
        villa.optional_boats.first.update model: "Foobar 9000"
      end

      scenario "erstellen" do
        navigate_to_inquiry_create
        enter_house_data curr, curr_values

        add_boat "Foobar 9000", villa_inquiry_params[:start_date] + 1.day, villa_inquiry_params[:end_date] - 1.day

        new_boat_price = find("tr", text: "13 Tage 1 Boot").find("td.text-right:last-child").text
        expect(new_boat_price).to eq curr_values.lookup_value("13 Tage 1 Boot")

        click_on "Speichern"
        expect_saved

        await_page_component_refresh ".admin-boat-selector .form-control.disabled"
        boat_inquiry = BoatInquiry.last

        within "form .form-group", text: "Boot" do
          date_range_picker.within_wrapper do
            expect(page).to display_date_range_picker_dates boat_inquiry.start_date, boat_inquiry.end_date
          end
        end

        within_price_table do
          expect_price_row_value_lookup("14 Nächte Grundpreis")
          expect_price_row_value_lookup("13 Tage 1 Boot")
          expect_price_row_value_lookup("Mietpreis", :with_optional_boat)
          expect_price_row_value_lookup("Mietkosten", :with_optional_boat)
          expect_price_row_value_lookup("Mietkosten inkl. Kaution", :with_optional_boat)

          expect_price_row_field_lookup("Endreinigung")
          expect_price_row_field_lookup("Boot-Anlieferung")
          expect_price_row_field_lookup("Haus-Kaution")
          expect_price_row_field_lookup("Boot-Kaution")
        end
      end
    end
  end

  context "EUR" do
    include_context "offers", Currency::EUR

    include_examples "mit Boot"
  end

  context "USD" do
    include_context "offers", Currency::USD

    include_examples "mit Boot"
  end
end
