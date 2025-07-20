require "rails_helper"

RSpec.feature "Admin::Bookings::Reviews", :js do
  include_context "as_admin"

  let!(:booking) { create_full_booking with_owner: true, with_manager: true }

  feature "Bewertung manuell erstellen" do
    let(:customer) { booking.customer }

    scenario do
      visit edit_admin_booking_path(booking)
      click_on "Bewertung"
      click_on "Manuell erstellen"

      fill_in "Bewertung", with: 2
      expect(page).to have_field "Name", with: customer.last_name
      expect(page).to have_field "Ort", with: customer.city
      fill_in "Kommentar", with: "foobar"
      check "freigeschaltet"

      click_on "speichern"
      expect(page).to have_content "Bewertung aktualisiert"

      visit "/admin/reviews"
      fill_in "Nummer", with: booking.id
      click_on "Suchen"

      within "table tr", text: booking.number do
        expect(page).to have_content "foobar"
      end
    end
  end
end
