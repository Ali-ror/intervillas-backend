require "rails_helper"

RSpec.feature "Boot ausblenden", :js do
  include_context "as_admin"

  let(:boat) { create :boat }
  let!(:villa) { create :villa, :editable }

  before do
    villa.optional_boats << boat
  end

  scenario do
    visit admin_root_path
    expect(boat.villas).not_to be_empty

    # Boot ist in der Zuordnungsauswahl
    within "header" do
      click_on "Objekte"
      click_on "Villen"
    end
    click_on "bearbeiten"
    expect(page).not_to have_content "Bitte warten, Daten werden geladen"
    click_on "Boote"
    expect(page).to have_content boat.admin_display_name

    # Boot ausblenden
    within "header" do
      click_on "Objekte"
      click_on "Boote"
    end
    within "tr", text: boat.formatted_matriculation_number do
      click_on "bearbeiten"
    end
    click_on "ausblenden"

    expect(page).to have_flash :info, "Boot wurde ausgeblendet"
    expect(page).not_to have_content boat.formatted_matriculation_number

    # Boot ist nicht mehr in der Zuordnungsauswahl
    within "header" do
      click_on "Objekte"
      click_on "Villen"
    end
    click_on "bearbeiten"
    expect(page).not_to have_content "Bitte warten, Daten werden geladen"
    click_on "Boote"
    expect(page).to have_content "Einschließlichkeit"
    choose "Boot optional buchbar"
    expect(page).not_to have_content boat.admin_display_name

    # Alle Zuordnungen wurden entfernt
    expect(boat.reload.villas).to be_empty
  end
end
