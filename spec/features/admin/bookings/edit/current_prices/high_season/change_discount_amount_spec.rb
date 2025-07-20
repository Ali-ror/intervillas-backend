require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"
  include_context "high season"

  shared_examples "anderer Prozentsatz" do
    scenario "anderer Prozentsatz" do
      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      expect_high_season_rents

      within ".sidebar-right .details-villa" do
        click_on "Hochsaison: Aufschlag bearbeiten"
      end

      within ".edit-discount-modal" do
        fill_in "Aufschlag", with: 50
        click_on "Speichern"
      end

      within_price_table do
        expect_price_row_value_lookup("14 Nächte + Hochsaison")
        click_on "Normalpreis vorhanden"
        click_on "übernehmen"
        expect_price_row_value_lookup("14 Nächte + Hochsaison", :high_season_50_percent)
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, nights: 14

    include_examples "anderer Prozentsatz"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, nights: 14

    include_examples "anderer Prozentsatz"
  end
end
