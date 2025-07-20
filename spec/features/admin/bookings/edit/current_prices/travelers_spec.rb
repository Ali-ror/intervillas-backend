require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  feature "persönliche Daten der Reisenden ändern" do
    let!(:booking) { create_full_booking with_owner: true, with_manager: true }
    let(:villa_inquiry) { booking.villa_inquiry }
    let(:travelers) { booking.travelers.order(price_category: :asc, last_name: :asc, first_name: :asc) }

    scenario do
      visit edit_admin_booking_path(booking)
      click_on "Buchungsdaten"

      sleep 1
      within_fieldset "Reisende" do
        travelers.each do |traveler|
          expect(page).to have_field "Nachname", with: traveler.last_name
          expect(page).to have_field "Vorname", with: traveler.first_name
        end

        within first("tbody tr") do
          fill_in "Vorname", with: "foo"
        end
      end

      click_on "Speichern"
      expect_saved
      tr = Traveler.find(travelers[0].id)
      expect(tr.first_name).to eq "foo"
      expect(page).not_to have_css "#price_table.refreshing"
      expect_occupancies_loaded
    end
  end

  shared_examples "Reisenden entfernen" do
    feature "Reisenden entfernen" do
      let(:travelers) { booking.travelers }

      scenario do
        visit edit_admin_booking_path(booking)
        click_on "Buchungsdaten"

        within_price_table do
          expect_price_row_value_lookup("7 Nächte Grundpreis")
          expect_price_row_value_lookup("7 Nächte 1 weitere Person(en)")
        end

        sleep 1
        # keine Ahnung warum, aber ohne den sleep hier wird die Preistabelle nicht
        # aktualisiert
        within_fieldset "Reisende" do
          within first("tbody tr") do
            click_on "Entfernen"
          end
        end

        within_price_table do
          expect_price_row_value_lookup("7 Nächte Grundpreis")
          expect(page).not_to have_content "weitere Person(en)"
        end

        expect {
          click_on "Speichern"
          expect_saved
        }.to change { booking.travelers.reload.count }.by(-1)

        expect(page).not_to have_content "Bitte warten"
      end
    end
  end

  context "EUR" do
    include_context "editable booking", Currency::EUR, adults: 3

    include_examples "Reisenden entfernen"
  end

  context "USD" do
    include_context "editable booking", Currency::USD, adults: 3

    include_examples "Reisenden entfernen"
  end
end
