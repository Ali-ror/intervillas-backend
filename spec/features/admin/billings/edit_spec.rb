require "rails_helper"

RSpec.feature "Nebenkosten", :js, :vcr do
  include_context "as_admin"

  def expect_owner_billing_row(category)
    expect(page).to have_content curr_values.lookup_owner_billing(category)
  end

  def expect_tenant_billing_row(category)
    expect(page).to have_content curr_values.lookup_tenant_billing(category)
  end

  shared_examples "abrechnen" do
    scenario do
      Setting.energy_price_eur = 0.12
      Setting.energy_price_usd = 0.16

      visit edit_admin_billing_path(booking)
      click_on "Villa"

      fill_in "Zählerstand (Beginn, kWh)", with: 2000
      fill_in "Zählerstand (Ende, kWh)", with: 2500
      expect(page).to have_field "Energiepreis", with: curr_values.lookup("Energiekosten pro kWh", format: false)[1]

      click_on "Abrechnung speichern"
      expect(page).to have_content "Abrechnung gespeichert"

      within ".sidebar-left" do
        click_on "Abrechnungen"
      end
      within ".row.owner-billing" do
        # TODO: hier später auch draufklicken, wenn Model-Tests fertig/besser
        expect(page).to have_link "PDF herunterladen"

        expect_owner_billing_row "Rent house"
        expect_owner_billing_row "Cleaning"
        expect_owner_billing_row "Electric"
        expect_owner_billing_row "Total taxable house"
        expect_owner_billing_row "6.5% Sales tax"
        expect_owner_billing_row "5% Tourist tax"
        expect_owner_billing_row "Total excluding taxes"
        expect_owner_billing_row "Admin Agency Fee"
        expect_owner_billing_row "Admin Commission"
        expect_owner_billing_row "Payout"
        expect_owner_billing_row "Taxes total"
      end

      within ".row.tenant-billing" do
        # TODO: hier später auch draufklicken, wenn Model-Tests fertig/besser
        expect(page).to have_link "PDF herunterladen"
      end

      click_on "Villa"

      click_on "weiteren Posten hinzufügen"
      fill_in "Beschreibung", with: "Fensterscheibe"
      fill_in "Wert", with: 300
      fill_in "Anzahl", with: 1
      click_on "Abrechnung speichern"

      within ".sidebar-left" do
        click_on "Abrechnung"
      end
      within ".row.tenant-billing" do
        # TODO: hier später auch draufklicken, wenn Model-Tests fertig/besser
        expect(page).to have_link "PDF herunterladen"

        expect(page).to have_content "Zählerstand Beginn 2000.0 kWh"
        expect(page).to have_content "Zählerstand Ende 2500.0 kWh"
        expect(page).to have_content "Verbrauch 500.0 kWh"

        expect_tenant_billing_row "Kaution Villa (Villa Foo)"
        expect_tenant_billing_row "Total Kaution"
        expect_tenant_billing_row "Energiekosten"
        expect_tenant_billing_row "Fensterscheibe"
        expect_tenant_billing_row "Total"
        expect_tenant_billing_row "Nachzahlung (Kaution – Kosten)"
      end
      click_on "Kommunikation"
      within ".owner-communication-form", text: "Abrechnung an Haus-Eigentümer versenden" do
        fill_in "Text", with: "test text"
        click_on "versenden"
      end

      expect(page).to have_flash "success", "Nachricht wird in Kürze versendet"
      click_on "Kommunikation"
      within ".tenant-communication-form", text: "Nebenkostenabrechnung an Mieter versenden" do
        fill_in "Text", with: "test text"
        click_on "versenden"
      end

      expect(page).to have_flash "success", "Nachricht wird in Kürze versendet"

      # Buchung mit anderer Währung im gleichen Abrechnungszeitraum erstellen.
      create_owner_clearing currency: curr == Currency::EUR ? Currency::USD : Currency::EUR, summary_on: booking.reload.summary_on

      click_on "Buchungen"
      click_link "Buchungen", href: "/admin/bookings" # rubocop:disable Capybara/ClickLinkOrButtonStyle
      click_on "Abgerechnet"
      expect(page).to have_content booking.villa.owner.display_name
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, villa_name: "Villa Foo"

    include_examples "abrechnen"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, villa_name: "Villa Foo"

    include_examples "abrechnen"
  end

  describe "energy cost calculation", vcr: { cassette_name: "villa/geocode" } do
    {
      %i[defer]                      => :defer,
      %i[defer legacy]               => :defer,
      %i[defer override_defer]       => :defer,
      %i[defer override_usage]       => :usage,
      %i[defer override_flat]        => :flat,
      %i[defer override_included]    => :included,

      %i[usage]                      => :usage,
      %i[usage legacy]               => :defer,
      %i[usage override_defer]       => :defer,
      %i[usage override_usage]       => :usage,
      %i[usage override_flat]        => :flat,
      %i[usage override_included]    => :included,

      %i[flat]                       => :flat,
      %i[flat legacy]                => :defer,
      %i[flat override_defer]        => :defer,
      %i[flat override_usage]        => :usage,
      %i[flat override_flat]         => :flat,
      %i[flat override_included]     => :included,

      %i[included]                   => :included,
      %i[included legacy]            => :defer,
      %i[included override_defer]    => :defer,
      %i[included override_usage]    => :usage,
      %i[included override_flat]     => :flat,
      %i[included override_included] => :included,
    }.each do |(villa_ecc, inquiry_ecc), behaviour|
      context "villa #{villa_ecc.inspect} and inquiry #{inquiry_ecc.inspect}" do
        include_context "editable booking", Currency::EUR, villa_name: "Villa Foo"

        it "is represented on billing page" do
          booking.inquiry.villa_inquiry.tap do |vi|
            vi.villa.update! energy_cost_calculation: villa_ecc
            vi.update! energy_cost_calculation: inquiry_ecc || villa_ecc
          end

          visit edit_admin_billing_path(booking)
          expect_attrs = case behaviour
          when :defer
            choose "Pauschale"
            expect(page).to have_css "label", text: "Zählerstand (Beginn, kWh)"
            expect(page).to have_css "label", text: "Zählerstand (Ende, kWh)"
            fill_in "Energiepreis", with: 200

            {
              energy_pricing:      "flat",
              meter_reading_begin: nil,
              meter_reading_end:   nil,
              energy_price:        200,
            }
          when :usage
            expect(page).to have_css ".form-group", text: "Abrechnungsart für Energiekosten Verbrauch abrechnen"
            fill_in "Zählerstand (Beginn, kWh)", with: 1000
            fill_in "Zählerstand (Ende, kWh)",   with: 1250
            fill_in "Energiepreis",              with: 0.5

            {
              energy_pricing:      "usage",
              meter_reading_begin: 1000,
              meter_reading_end:   1250,
              energy_price:        0.5,
            }
          when :flat
            expect(page).to have_css ".form-group", text: "Abrechnungsart für Energiekosten Pauschale"
            expect(page).to have_no_css "label", text: "Zählerstand (Beginn, kWh)"
            expect(page).to have_no_css "label", text: "Zählerstand (Ende, kWh)"
            fill_in "Energiepreis", with: 500

            {
              energy_pricing:      "flat",
              meter_reading_begin: nil,
              meter_reading_end:   nil,
              energy_price:        500,
            }
          when :included
            expect(page).to have_css ".form-group", text: "Abrechnungsart für Energiekosten enthalten im Mietpreis"
            expect(page).to have_no_css "label", text: "Zählerstand (Beginn, kWh)"
            expect(page).to have_no_css "label", text: "Zählerstand (Ende, kWh)"
            expect(page).to have_no_css "label", text: "Energiepreis"

            {
              energy_pricing:      "included",
              meter_reading_begin: nil,
              meter_reading_end:   nil,
              energy_price:        nil,
            }
          else
            raise ArgumentError, "unexpected behaviour"
          end

          click_on "Abrechnung speichern"
          expect(page).to have_content "Abrechnung gespeichert"
          expect(booking.billings.first).to have_attributes(expect_attrs)
        end
      end
    end
  end
end
