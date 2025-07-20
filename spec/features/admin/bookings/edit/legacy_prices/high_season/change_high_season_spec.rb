require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"
  include_context "high season"

  delegate :start_date, to: :villa_inquiry

  shared_examples "anderer Zeitraum" do
    scenario "anderer Zeitraum" do
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
        date_range_picker.select_dates start_date - 7.days, start_date + 3.days
        click_on "Speichern"
      end

      expect_price_row_value_lookup("3 Nächte 2 + Hochsaison")
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, legacy_prices: true, nights: 14

    include_examples "anderer Zeitraum"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, legacy_prices: true, nights: 14

    include_examples "anderer Zeitraum"
  end
end
