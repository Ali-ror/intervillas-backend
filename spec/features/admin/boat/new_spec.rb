require "rails_helper"

RSpec.describe "Boot", :js do
  include_context "as_admin"

  let!(:manager) { create :contact }
  let!(:owner) { create :contact }
  let!(:boat) { create :boat, :with_prices, model: "Test Boat", matriculation_number: "123F00" }

  before do
    visit admin_root_path
    click_on "Objekte"
    click_on "Boote"
  end

  scenario "anlegen" do
    click_on "neues Boot anlegen"

    fill_in "Modell", with: "Test Boot"
    fill_in "PS", with: "75 - 234"
    fill_in "Immatrikulationsnummer", with: "42F00"
    fill_in "Beschreibung", with: Faker::Lorem.paragraph
    fill_in "Beschreibung auf Englisch", with: Faker::Lorem.paragraph
    fill_in "Link", with: "http://www.google.de"
    ui_select manager.name, from: "Bootsverwaltung"
    ui_select owner.name, from: "Eigentümer"

    fill_in "Mindest-Mietdauer in Tagen", with: 4
    click_on "speichern"

    expect(page).to have_flash :info, /Boot '\d+ - Test Boot' wurde erfolgreich gespeichert/
    expect(page).to have_current_path edit_admin_boat_path(Boat.last), ignore_query: true
    expect(page).to have_css ".list-group-item.active", text: "Test Boot"

    expect(page).to have_ui_select "Bootsverwaltung", selected: manager.name
    expect(page).to have_ui_select "Eigentümer", selected: owner.name
    expect(page).to have_field "Mindest-Mietdauer in Tagen", with: 4

    click_on "Preise"
    within ".prices" do
      fill_in "Anlieferung (EUR)", with: "100"
      fill_in "Kaution (EUR)", with: "150"
    end

    click_on "Preise speichern"
    expect(page).to have_text "Preise erfolgreich gespeichert"
  end

  scenario "ändern" do
    within "tr", text: boat.formatted_matriculation_number do
      click_on "bearbeiten"
    end

    fill_in "Modell", with: "Test Boot"
    fill_in "Beschreibung", with: Faker::Lorem.paragraph
    fill_in "Beschreibung auf Englisch", with: Faker::Lorem.paragraph
    fill_in "Link", with: "http://www.google.de"

    click_on "speichern"

    expect(page).to have_flash :info, /Boot '\d+ - Test Boot' wurde erfolgreich gespeichert/
    expect(page).to have_current_path edit_admin_boat_path(Boat.last), ignore_query: true
    expect(page).to have_css ".list-group-item.active", text: "Test Boot"
  end

  context "Preise" do
    before do
      within "tr", text: boat.formatted_matriculation_number do
        click_on "bearbeiten"
      end

      click_on "Preise"
    end

    scenario "hinzufügen" do
      within ".prices" do
        click_on "Preis hinzufügen"
        fill_in "4 Tage (EUR)", with: 42.42
      end

      expect {
        click_on "Preise speichern"
        expect(page).to have_text "Preise erfolgreich gespeichert"
      }.to change(boat.prices_eur, :count).by(1)
    end

    scenario "entfernen" do
      click_on "Preise für 3 Tage entfernen"
      expect {
        click_on "Preise speichern"
        expect(page).to have_text "Preise erfolgreich gespeichert"
      }.to(change { boat.prices_eur.valid_now.count }.by(-1))
    end
  end

  scenario "Aufschlag hinzufügen" do
    within "tr", text: boat.formatted_matriculation_number do
      click_on "bearbeiten"
    end

    click_on "Preise"
    within ".panel", text: "Weihnachten" do
      fill_in "Aufschlag",   with: 20
      fill_in "Tage vorher", with: 1
      fill_in "Tage danach", with: 14
    end

    within ".panel", text: "Ostern" do
      fill_in "Aufschlag",   with: 15
      fill_in "Tage vorher", with: 3
      fill_in "Tage danach", with: 7
    end

    expect {
      click_on "Preise speichern"
      expect(page).to have_text "Preise erfolgreich gespeichert"
    }.to change(boat.holiday_discounts, :count).by(2)
  end

  context "with christmas discount" do
    before do
      create :holiday_discount, :christmas, boat: boat
    end

    scenario "Aufschlag entfernen" do
      within "tr", text: boat.formatted_matriculation_number do
        click_on "bearbeiten"
      end

      click_on "Preise"
      within ".panel", text: "Weihnachten" do
        click_on "löschen"
      end

      expect {
        click_on "Preise speichern"
        expect(page).to have_text "Preise erfolgreich gespeichert"
      }.to change(boat.holiday_discounts, :count).by(-1)
    end
  end
end
