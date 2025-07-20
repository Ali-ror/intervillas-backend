require "rails_helper"

RSpec.feature "Admin::Contacts::AssignRentables", vcr: { cassette_name: "admin_villa/geocode" } do
  include_context "as_admin"

  # 2 Villen
  let!(:villas) { create_list :villa, 2, :editable, :displayable, :with_geocode }
  let(:villa) { villas.first }

  # Eigentümer und Verwaltung
  let!(:villa_owner)   { create :contact, :with_user }
  let!(:villa_manager) { create :contact }

  # einer Villa davon den Kontakt zuordnen
  scenario "assign rentable", :js do
    visit admin_root_path
    click_on "Objekte"
    click_on "Villen"

    within "tr", text: villa.name do
      click_on "bearbeiten"
    end

    ui_select villa_owner.name, from: "Eigentümer"
    ui_select villa_manager.name, from: "Hausverwaltung"
    fill_in "Telefonnummer", with: "(555) 123-456"

    click_on "Speichern"
    expect(page).to have_css ".alert-success", text: "erfolgreich gespeichert"

    # mit Account des Kontakts einloggen
    using_ephemeral_session "of a contact" do
      sign_in villa_owner.users.first
      visit user_root_path

      # prüfen, dass nur die zugeordnete Villa sichtbar ist
      expect(page).to have_link villa.admin_display_name
      expect(page).to have_no_link villas[1].admin_display_name
    end
  end
end
