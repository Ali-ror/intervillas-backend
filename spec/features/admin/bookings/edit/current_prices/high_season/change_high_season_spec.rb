require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"
  include_context "high season"

  shared_examples "anderer Zeitraum" do
    delegate :start_date, to: :villa_inquiry

    scenario "anderer Zeitraum" do
      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      expect_high_season_rents

      within ".sidebar-right .details-villa" do
        click_on "Hochsaison: Aufschlag bearbeiten"
      end

      within ".edit-discount-modal" do
        date_range_picker.select_dates start_date - 7.days, start_date + 3.days
        click_on "Speichern"
      end

      expect_price_row_value_lookup("3 Nächte + Hochsaison")
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, nights: 14

    include_examples "anderer Zeitraum"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, nights: 14

    include_examples "anderer Zeitraum"
  end
end
