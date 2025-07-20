require "rails_helper"

RSpec.feature "Reiseteilnehmer mit unterschiedlichen Reisedaten", :js do
  include_context "as_admin"

  def expect_price_rows_by_dates(*dates, nights:, adults:)
    expect_price_row_value_lookup_with_dates("#{nights} Nächte, Grundpreis für 2 Pers.", dates: dates)
    return unless adults > 2

    expect_price_row_value_lookup_with_dates("#{nights} Nächte, #{adults - 2} weitere Person(en)", dates: dates)
  end

  shared_examples "hinzufügen" do
    scenario "hinzufügen" do
      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      add_traveler "Kommt", "Später", late_arrival, end_date
      add_traveler "Geht", "Früher", start_date, early_leave

      expect(page).not_to have_selector ".js-price-table.refreshing"

      # 2 Nächte 3 Erwachsene
      expect_price_rows_by_dates start_date, late_arrival, nights: 2, adults: 3

      # 3 Nächte 4 Erwachsene
      expect_price_rows_by_dates late_arrival, early_leave, nights: 3, adults: 4

      # 2 Nächte 3 Erwachsene
      expect_price_rows_by_dates early_leave, end_date, nights: 2, adults: 3

      click_on "Speichern"
      expect(page).to have_content "Buchungsdaten erfolgreich gespeichert"
    end
  end

  context "EUR" do
    include_context "diverse travel dates"
    include_context "villa_inquiry", Currency::EUR

    include_examples "hinzufügen"
  end

  context "USD" do
    include_context "diverse travel dates"
    include_context "villa_inquiry", Currency::USD

    include_examples "hinzufügen"
  end
end
