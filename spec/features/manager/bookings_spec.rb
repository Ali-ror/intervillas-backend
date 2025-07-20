require "rails_helper"

RSpec.feature "Manager Access", :js do
  include_context "as_manager"

  let(:villa) { manager.managed_villas.first }
  let!(:booking) { create_full_booking start_date: 1.day.from_now, villa: villa }

  scenario "Buchungen" do
    click_on "Buchungen"
    click_on "Buchungen/Anfragen/Angebote"

    expect(page).to have_no_link "Anfragen/Angebote", exact: true

    within "tr", text: booking.number do
      expect(page).to have_no_link "anzeigen"
    end
  end

  context "mit Zugriffsberechtigung" do
    before do
      manager.users.first.tap { |u|
        u.access_level = "bookings"
        u.save!
      }
    end

    scenario "Buchungen" do
      click_on "Buchungen"
      click_on "Buchungen/Anfragen/Angebote"

      expect(page).to have_link "Anfragen/Angebote", exact: true

      within "tr", text: booking.number do
        click_on "anzeigen"
      end
    end
  end

  scenario "Kalender" do
    within "tr", text: villa.admin_display_name do
      first(:link, "anzeigen").click
    end

    expect(page).to have_content booking.number
  end
end
