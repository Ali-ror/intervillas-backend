require "rails_helper"

RSpec.feature "Reiseteilnehmer mit unterschiedlichen Reisedaten", :js do
  include_context "as_admin"

  shared_examples "hinzufügen" do
    scenario "hinzufügen" do
      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      add_traveler "Kommt", "Später", late_arrival, end_date
      add_traveler "Geht", "Früher", start_date, early_leave

      expect(page).not_to have_css ".js-price-table.refreshing"

      [
        ["2 Nächte, 3 Erwachsene", start_date, late_arrival],
        ["3 Nächte, 4 Erwachsene", late_arrival, early_leave],
        ["2 Nächte, 3 Erwachsene", early_leave, end_date],
      ].each do |(name, *dates)|
        prices = curr_values.lookup_changing_total(name)
        expect_normal_price_changing_total(name, *dates, **prices)
      end

      click_on "Speichern"
      expect(page).to have_content "Buchungsdaten erfolgreich gespeichert"
    end
  end

  context "EUR" do
    include_context "diverse travel dates"
    include_context "villa_inquiry", Currency::EUR, legacy_prices: true

    include_examples "hinzufügen"
  end

  context "USD" do
    include_context "diverse travel dates"
    include_context "villa_inquiry", Currency::USD, legacy_prices: true
    include_examples "hinzufügen"
  end
end
