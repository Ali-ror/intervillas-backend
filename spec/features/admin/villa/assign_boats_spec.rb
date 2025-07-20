require "rails_helper"

RSpec.feature "Boote zu Häusern zuordnen", :js, :vcr do
  include_context "as_admin"

  let!(:villa) { create :villa, :editable }
  let!(:boat) { create :boat }

  context "festes Boot" do
    scenario do
      visit admin_villas_path
      within "tr", text: villa.name do
        expect(page).to have_content "keins"
      end
      visit edit_admin_villa_path(villa)
      click_on "Boote"
      choose "eigenes Boot (im Mietpreis enthalten)"
      choose boat.admin_display_name
      click_on "Speichern"

      expect(page).to have_css ".alert-success", text: "erfolgreich gespeichert"
      expect(page).to have_checked_field "eigenes Boot (im Mietpreis enthalten)"
      expect(page).to have_checked_field boat.admin_display_name

      within "header" do
        click_on "Objekte"
        click_on "Villen"
      end

      within "tr", text: villa.name do
        expect(page).to have_content "inklusive"
      end
    end
  end

  context "optionale Boote" do
    scenario do
      visit admin_villas_path
      within "tr", text: villa.name do
        expect(page).to have_content "keins"
      end
      visit edit_admin_villa_path(villa)
      click_on "Boote"
      choose "Boot optional buchbar"
      check boat.admin_display_name
      click_on "Speichern"

      expect(page).to have_css ".alert-success", text: "erfolgreich gespeichert"
      expect(page).to have_checked_field "Boot optional buchbar"
      expect(page).to have_checked_field boat.admin_display_name

      within "header" do
        click_on "Objekte"
        click_on "Villen"
      end

      within "tr", text: villa.name do
        expect(page).to have_content "optional"
      end
    end
  end
end
