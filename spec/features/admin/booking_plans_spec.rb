require "rails_helper"

RSpec.feature "Belegungspläne", :js do
  include_context "as_admin"

  around do |ex|
    date = Date.parse "#{Date.current.year}-#{Date.current.month}-01"
    Timecop.travel date, &ex
  end

  let!(:booking)      { create_full_booking start_date: Date.current }
  let(:villa)         { booking.villa }
  let(:villa_inquiry) { booking.villa_inquiry }
  let!(:blocking)     { create :blocking, villa: villa, start_date: villa_inquiry.end_date }
  let!(:inquiry)      { create_villa_inquiry(start_date: booking.start_date, villa: villa).inquiry }

  scenario "Monatsplan für Villa" do
    visit admin_root_path
    click_link "Buchungen", href: "#"
    click_on "Belegungspläne Villen"

    click_on villa.name
    expect(page).to have_css ".nav-tabs li.active", text: "Kalender"
    expect(page).to have_content booking.number
    expect(page).to have_content inquiry.number

    click_on "Liste"
    expect(page).to have_content booking.number
  end

  scenario "Jahresplan für Villa" do
    visit admin_root_path
    click_link "Buchungen", href: "#"
    click_on "Belegungspläne Villen"

    click_on villa.name
    click_on booking.start_date.year.to_s
    expect(page).to have_content booking.number
  end

  scenario "Belegungspläne alle Villen" do
    visit admin_root_path
    click_link "Buchungen", href: "#"
    click_on "Belegungspläne Villen"

    start_date = villa_inquiry.start_date
    within "table.occupancies tr", text: start_date.year do
      title = [I18n.t("date.month_names")[start_date.month], start_date.year].join(" ")
      click_link title
    end

    expect(page).to have_content booking.number
    expect(page).to have_content blocking.number
  end
end
