require "rails_helper"

RSpec.describe "Hochsaison", :js do
  include_context "as_admin"

  let!(:villa) { create :villa }

  matcher :have_screen_reader_text do |expected|
    match do |actual|
      actual.has_selector? ".sr-only", text: expected, visible: false
    end
  end

  scenario "anlegen" do
    visit admin_root_path
    click_on "Objekte"
    click_on "Hochsaison"
    click_on "hinzufügen"

    year_start = Date.current.year
    year_end   = year_start + 1

    within ".form-group", text: "Zeitraum" do
      date_range_picker.select_dates "#{year_start}-12-15", "#{year_end}-04-08"
    end
    fill_in "Aufschlag", with: 20
    check villa.name
    click_on "speichern"

    name = "#{year_start}-#{year_end % 100}"
    expect(page).to have_selector "thead th", text: "#{name} 15.12.#{year_start} 08.04.#{year_end} 20 %"
    expect(page).to have_screen_reader_text "Hochsaison #{name} gilt für Villa #{villa.admin_display_name}"
  end

  context "existierende Hochsaison" do
    let!(:other_villa)  { create :villa }
    let!(:high_season)  { create :high_season, villas: [villa] }
    let(:year_start)    { high_season.starts_on.year }
    let(:year_end)      { high_season.ends_on.year }

    it "bearbeiten" do
      visit admin_root_path
      click_on "Objekte"
      click_on "Hochsaison"

      expect(page).to have_screen_reader_text "Hochsaison #{high_season.name} gilt für Villa #{villa.admin_display_name}"
      expect(page).to have_screen_reader_text "Hochsaison #{high_season.name} gilt nicht für Villa #{other_villa.admin_display_name}"

      click_on "Hochsaison #{high_season.name} bearbeiten"

      within ".form-group", text: "Zeitraum" do
        expect(page).to have_content "15.12.#{year_start}"
        expect(page).to have_content "31.05.#{year_end}"
      end
      expect(page).to have_field "Aufschlag", with: "20"
      expect(page).to have_checked_field villa.name

      new_start = year_start + 1
      new_end   = year_end + 1

      within ".form-group", text: "Zeitraum" do
        date_range_picker.select_dates "#{new_start}-12-15", "#{new_end}-04-09"
      end
      fill_in "Aufschlag", with: 21

      uncheck villa.name
      check other_villa.name
      click_on "speichern"

      name = "#{new_start}-#{new_end % 100}"

      expect(page).to have_selector "thead th", text: "#{name} 15.12.#{new_start} 09.04.#{new_end} 21 %"
      expect(page).to have_screen_reader_text "Hochsaison #{name} gilt nicht für Villa #{villa.admin_display_name}"
      expect(page).to have_screen_reader_text "Hochsaison #{name} gilt für Villa #{other_villa.admin_display_name}"
    end

    it "löschen" do
      visit admin_root_path
      click_on "Objekte"
      click_on "Hochsaison"

      accept_confirm "Wirklich löschen?" do
        click_on "Hochsaison #{high_season.name} löschen"
      end

      expect(page).to have_flash :info, "Hochsaison gelöscht"
      expect(page).to have_content "Bisher keine Hochsaisons definiert."
    end
  end
end
