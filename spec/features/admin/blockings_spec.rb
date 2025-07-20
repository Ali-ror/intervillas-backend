require "rails_helper"

RSpec.describe "Termine blockieren", :js do
  include_context "as_admin"

  let!(:villa) { create :villa }
  let(:blocking) { create :blocking, villa: villa, start_date: current_date(day: 7) }

  def current_date(day:)
    current = Date.current
    Date.new current.year, current.month, day
  end

  def click_calendar(day:)
    find("td.fc-day[data-date='#{current_date(day: day)}']").click
  end

  def click_event(text)
    first(".fc-event", text: text).click
  end

  scenario "blockieren" do
    visit admin_root_path
    within "#main-menu" do
      click_on "Buchungen"
    end
    click_on "Belegungspläne Villen"
    click_on villa.name

    within ".js-calendar" do
      expect(page).to have_css "td", text: "7"
      click_calendar day: 7
      click_calendar day: 15
    end

    expect(page).to have_content "Termin Blockieren"
    expect(page).to have_select "Haus", selected: villa.name
    expect(page).to have_field "Beginn", with: current_date(day: 7)
    expect(page).to have_field "Ende", with: current_date(day: 15)

    fill_in "Kommentar", with: "foobar"
    click_on "Termin blockieren"

    expect(page).to have_content "foobar Termin blockiert"
    expect(page).to have_content Blocking.last.number
  end

  scenario "Blockierung ändern" do
    expect(blocking).to be_persisted
    visit admin_root_path
    within "#main-menu" do
      click_on "Buchungen"
    end
    click_on "Belegungspläne Villen"
    click_on villa.name

    within ".js-calendar" do
      expect(page).to have_content blocking.number
      click_event blocking.number
    end

    expect(page).to have_select "Haus", selected: villa.name
    expect(page).to have_field "Beginn", with: blocking.start_date
    expect(page).to have_field "Ende", with: blocking.end_date
    expect(page).to have_field "Kommentar", with: blocking.comment

    new_end = blocking.end_date + 2.days
    fill_in "Ende", with: new_end
    click_on "Termin blockieren"

    expect(page).to have_css "h4", text: "Jahrespläne"
    expect(blocking.reload.end_date).to eq new_end
  end

  scenario "Termin freigeben" do
    visit admin_root_path
    expect(blocking).to be_persisted
    within "#main-menu" do
      click_on "Buchungen"
    end
    click_on "Belegungspläne Villen"
    click_on villa.name

    within ".js-calendar" do
      expect(page).to have_content blocking.number
      click_event blocking.number
    end

    click_on "Termin freigeben"

    within ".js-calendar" do
      expect(page).to have_no_content blocking.number
    end
    expect { blocking.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
