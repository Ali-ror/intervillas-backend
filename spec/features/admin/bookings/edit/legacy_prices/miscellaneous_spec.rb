require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  include_context "editable booking", Currency::EUR, legacy_prices: true

  feature "Sonstiges ändern" do
    let(:inquiry) { booking.inquiry }

    before do
      inquiry.comment = "this is a comment"
      inquiry.save!
    end

    scenario do
      visit edit_admin_booking_path(booking)
      within "aside.sidebar-left" do
        click_on "Sonstiges"
      end

      expect(page).to have_field "Kommentar", with: "this is a comment"

      fill_in "Kommentar", with: "foobarfoo"
      click_on "Speichern"

      expect_saved
      expect(page).to have_field "Kommentar", with: "foobarfoo"
      expect_occupancies_loaded
    end
  end
end
