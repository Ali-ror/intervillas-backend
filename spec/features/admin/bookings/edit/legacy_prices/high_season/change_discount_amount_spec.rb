require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"
  include_context "high season"

  shared_examples "anderer Prozentsatz" do
    scenario "anderer Prozentsatz" do
      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      within_price_table do
        expect_price_row_value_lookup("14 Nächte 2 Erwachsene")
        expect_price_row_value_lookup("14 Nächte 2 + Hochsaison")
        expect_price_row_value_lookup("Mietpreis", :high_season)
      end

      within ".sidebar-right .details-villa" do
        click_on "Hochsaison: Aufschlag bearbeiten"
      end

      within ".edit-discount-modal" do
        fill_in "Aufschlag", with: 50
        click_on "Speichern"
      end

      expect_price_row_value_lookup("14 Nächte 2 + Hochsaison")
      click_on "Normalpreis vorhanden"
      click_on "übernehmen"
      expect_price_row_value_lookup("14 Nächte 2 + Hochsaison", :high_season_50_percent)
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, legacy_prices: true, nights: 14

    include_examples "anderer Prozentsatz"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, legacy_prices: true, nights: 14

    include_examples "anderer Prozentsatz"
  end
end
