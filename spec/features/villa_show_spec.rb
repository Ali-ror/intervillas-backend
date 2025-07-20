require "rails_helper"

RSpec.describe "Villa" do
  specify "show", vcr: { cassette_name: "villa/geocode" } do
    villa = create(:villa, :with_mandatory_boat, name: "villa", living_area: 265)
    villa.tag_with("kamin", "livingroom")
    villa.tag_with("sitzgelegenheiten", "livingroom", 8)
    cat   = create(:category, :highlights)
    create(:description, key: "description", text: "test description", category: cat, villa: villa)

    cat       = create(:category, :bedrooms)
    bedroom_a = villa.areas.create! category: cat, subtype: "schlafzimmer", beds_count: 3
    bedroom_b = villa.areas.create! category: cat, subtype: "schlafzimmer", beds_count: 2
    bedroom_a.tag_with("doppelbett", "schlafzimmer", 1)
    bedroom_a.tag_with("einzelbett", "schlafzimmer", 1)
    bedroom_b.tag_with("doppelbett", "schlafzimmer", 1)

    cat_b      = create(:category, :bathrooms)
    bathroom_a = villa.areas.create! category: cat_b, subtype: "vollbad"
    bathroom_b = villa.areas.create! category: cat_b, subtype: "duschbad"
    bathroom_c = villa.areas.create! category: cat_b, subtype: "gaestewc"
    bathroom_a.tag_with("wc", "badezimmer")
    bathroom_b.tag_with("wc", "badezimmer")
    bathroom_c.tag_with("wc", "badezimmer")
    boat       = villa.inclusive_boat

    %w[kamin sitzgelegenheiten doppelbett einzelbett doppelbett wc].each do |tag_name|
      tag = Tag.find_by! name: tag_name
      tr  = tag_name.titleize
      tag.translations.create \
        locale:     I18n.locale,
        name_one:   (tr unless tag.countable?),
        name_other: (tag.countable? ? "%{count} #{tr}" : tr)
    end

    create(:villa_price, villa: villa)
    visit villa_path(villa)

    expect(page).to have_content("Wohnfläche: 265")
    expect(page).to have_content("2 Schlafzimmer")
    expect(page).to have_content("Schlafmöglichkeiten für 5")
    expect(page).to have_content("2 Badezimmer")
    expect(page).to have_content("3 WC/Toiletten")

    click_on "Alle Ausstattungsmerkmale ansehen"
    expect(page).to have_content("Wohnraum")
    click_link "Wohnraum"
    expect(page).to have_content("Kamin")
    expect(page).to have_content(boat.model)
  end
end
