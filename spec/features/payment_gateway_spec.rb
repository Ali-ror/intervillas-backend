require "rails_helper"

RSpec.feature "Zahlung über Dienstleister", :js, :vcr do
  def within_column(column, &block)
    within :xpath, "//table/tbody/tr/td[#{column}]", &block
  end

  shared_examples "Zahlung über PayOne" do
    scenario "bsp1" do
      visit payments_path(booking.inquiry.token)
      expect(page).to have_content(/Total Eingang [$€] 0,00/)

      amount = fake_bsp1_payment(booking)
      page.driver.refresh

      # Zahlungstatus wird aktualisiert
      expect(page).to have_content "Erfasste Zahlungseingänge"
      expect(page).to have_content(/Offener Betrag [$€] 0,00/)

      # im Admin-Bereich ist die Zahlung abgeschlossen
      using_ephemeral_session "admin" do
        sign_in_admin
        visit "/admin"
        click_on "Zahlungen"
        click_on "Alle"
        within "tr", text: booking.number do
          # Anzahlung hat colspan=2 bei kurzfristigen Buchungen
          late_col_offset = booking.late? ? 0 : 1

          within_column(5 + late_col_offset) do # Zahlungseingang
            payment = display_price(amount).sub("\u00a0", " ") # nbsp → sp
            expect(page).to have_content payment
          end

          within_column(6 + late_col_offset) do # "Differenz" (offener Betrag)
            expect(page).to have_content(/[$€] 0,00/)
          end
        end
      end
    end
  end

  shared_examples "Zahlung über PayPal" do
    scenario "paypal" do
      visit payments_path(booking.inquiry.token)
      expect(page).to have_content(/Total Eingang [$€] 0,00/)

      fake_paypal_payment(booking)
      page.driver.refresh

      # Zahlungstatus wird aktualisiert
      expect(page).to have_content "Erfasste Zahlungseingänge"
      expect(page).to have_content(/Offener Betrag [$€] 0,00/)

      # im Admin-Bereich ist dei Zahlung abgeschlossen
      using_ephemeral_session "admin" do
        sign_in_admin
        visit "/admin"
        click_on "Zahlungen"
        click_on "Alle"
        within "tr", text: booking.number do
          within_column(6) do
            expect(page).to have_content(/[$€] 0,00/)
          end
        end
      end
    end
  end

  context "for GmbH" do
    travel_to_gmbh_era!(offset: -2.days)

    context "EUR" do
      include_context "editable booking", Currency::EUR,
        start_date: corporate_switch_date - 2.days
      include_examples "Zahlung über PayOne"
    end

    context "USD" do
      include_context "editable booking", Currency::USD,
        start_date: corporate_switch_date - 2.days
      include_examples "Zahlung über PayOne"
    end
  end

  context "for Corp" do
    travel_to_corp_era!(offset: 2.days)

    context "EUR" do
      include_context "editable booking", Currency::EUR,
        start_date: corporate_switch_date + 2.days
      include_examples "Zahlung über PayPal"
    end

    context "USD" do
      include_context "editable booking", Currency::USD,
        start_date: corporate_switch_date + 2.days
      include_examples "Zahlung über PayPal"
    end
  end
end
