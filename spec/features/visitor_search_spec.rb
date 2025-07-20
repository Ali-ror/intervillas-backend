require "rails_helper"

RSpec.describe "Search", :js do
  let!(:villa)       { create :villa, :displayable, :bookable, pool_orientation: "e" }
  let!(:other_villa) { create :villa, :displayable, :bookable, pool_orientation: "se" }
  let(:from)         { 1.year.from_now.to_date }
  let(:to)           { (1.year.from_now + 2.weeks).to_date }

  def expect_input_value(name, value)
    expect(page).to have_css format('input[name="%s"][value="%s"]', name, value)
  end

  def expect_input_value_not(name, value)
    expect(page).not_to have_css format('input[name="%s"][value="%s"]', name, value)
  end

  specify "a visitor searches on homepage" do
    # Suche auf Startseite
    visit "/"
    within "#reservation-form" do
      date_range_picker.select_dates(from, to)
    end

    # Ergebnisseite
    expect(page).to have_content "2 Villen zu Ihrer Suchanfrage gefunden"
    within ".room-grid" do
      click_link villa.name
    end

    # Suchdaten auf Villa-Seite übernommen
    dates = [from, to].map { |t| t.strftime("%d.%m.%Y") }.join(" – ")
    expect(page).to have_content "Reisezeitraum #{dates}"

    # Suchdaten nicht übernommen bei direktem Aufruf einer Villa-Seite
    within first(".navbar-nav") do
      click_on "Ferienhaus Cape Coral"
    end
    click_link other_villa.name

    expect_input_value_not("start_date", from)
    expect_input_value_not("end_date", to)
  end

  specify "a visitor filters features" do
    # other_villa mit individuellem Tag versehen
    cat = create :category, :highlights
    tag = create :tag, category: cat, name: "egal", filterable: true
    tag.translations.create locale: "de", description: "Sitzball", name_other: "Sitzball"
    other_villa.tag_with "egal", "highlights", 1
    other_villa.save!

    visit "/villas"
    click_on "Suchen"

    expect(page).to have_content "2 Villen zu Ihrer Suchanfrage gefunden"
    expect(page).to have_content villa.name
    expect(page).to have_content other_villa.name

    # 1. Facette aktivieren = villa ausblenden
    click_on "mehr Filter"
    find("label", text: "Sitzball").click # custom checkbox

    expect(page).to     have_content "Eine Villa zur Ihrer Suchanfrage gefunden"
    expect(page).not_to have_content villa.name
    expect(page).to     have_content other_villa.name

    # 2. Zeitraum auswählen = villa bleibt ausgeblendet
    date_range_picker.select_dates from, to
    expect(page).not_to have_content villa.name
    expect(page).to     have_content other_villa.name

    # 3. Aurichtung Pool ändern = other_villa verschwindet
    find("label", text: "Süd-Ost").click
    expect(page).to     have_content "Für diese Suchanfrage haben wir leider keine Villen gefunden"
    expect(page).not_to have_content villa.name
    expect(page).not_to have_content other_villa.name

    # 4. Facetten zurücksetzen = villa,other_villa wird wieder eingeblendet
    click_on "weniger Filter"
    expect(page).to have_content "2 Villen zu Ihrer Suchanfrage gefunden"
    expect(page).to have_content villa.name
    expect(page).to have_content other_villa.name
  end
end
