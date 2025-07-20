require "rails_helper"

RSpec.feature "Satelliten-Seiten", :js do
  let(:name) { "cape-coral-ferienhaeuser.com" }

  let!(:page_a)   { create :page, name: "Allgemeine Geschäftsbedingungen" }
  let!(:page_b)   { create :page, name: "Impressum" }
  let!(:page_c)   { create :page, name: "Einreisebestimmungen" }
  let!(:villa_a)  { create :villa, :bookable, :with_owner, :with_manager }
  let!(:villa_b)  { create :villa, :bookable, :with_owner, :with_manager }
  let!(:boat_a)   { create :boat, :with_prices }
  let!(:boat_b)   { create :boat, :with_prices }

  let(:undo_uppy_hide_file_input) {
    {
      # force visibility for Capybara
      opacity:      1,
      display:      "block",
      visibility:   "visible",
      width:        "auto",
      height:       "auto",
      "z-index"  => 1,
    }
  }

  before do
    sign_in_admin
    visit "/admin/domains"
  end

  def check_toggle_item(name)
    click_on "#{name} aktivieren"
  end

  def uncheck_toggle_item(name)
    click_on "#{name} deaktivieren"
  end

  it "create new domain" do
    click_on "neue Satelliten-Seite anlegen"
    expect(page).to have_content "Globale Einstellungen"

    # Test 1: editor UI

    fill_in "Branding", with: "Cape Coral Ferienhäuser"
    check   "Mehrsprachig?"
    uncheck "Ökosystem-Seite?"

    within "#domain_partials" do
      check_toggle_item "Button/Link-Zeile"
      check_toggle_item "Promo-Video"
      check_toggle_item "SEO-Text-Block"
    end

    expect(page).to have_content "Slider-Bilder können erst eingerichtet werden, nachdem die Domain gespeichert wurde."

    fill_in "Titel auf deutsch",        with: "html title de"
    fill_in "Beschreibung auf deutsch", with: "meta desc de"
    fill_in "Überschrift auf deutsch",  with: "page heading de"
    fill_in "Text auf deutsch",         with: "# Hallo Welt!!\n"

    fill_in "Titel auf english",        with: "html title en"
    fill_in "Beschreibung auf english", with: "meta desc en"
    fill_in "Überschrift auf english",  with: "page heading en"
    fill_in "Text auf englisch",        with: "# Hello World!\n"

    within ".domain_content_de" do
      click_on "Vollbild mit Vorschau"
    end
    expect(page).to have_css "h4", text: "Vorschau"
    within ".preview" do
      expect(page).to have_content "Hallo Welt!!"
    end
    click_on "Editor schließen"

    within "#domain_pages" do
      check_toggle_item page_a.name
      check_toggle_item page_b.name
    end

    within "#domain_villas" do
      check_toggle_item villa_a.admin_display_name
    end

    within "#domain_boats" do
      check_toggle_item boat_b.admin_display_name
    end

    click_on "Speichern"
    expect(page).to have_content "Beim Speichern sind Fehler aufgetreten:"
    expect(page).to have_content "Domain-Name muss ausgefüllt werden"
    fill_in "Domain-Name", with: name

    click_on "Speichern"
    expect(page).to have_content "Satelliten-Seite #{name} erfolgreich erstellt."

    # Test 2: API endpoint

    domain = Domain.find_by!(name: name)
    expect(domain.brand_name).to eq "Cape Coral Ferienhäuser"
    expect(domain.multilingual?).to be true
    expect(domain.interlink?).to be false
    expect(domain.partials).to match_array %w[buttons_villas_specials promo_video seo_block]
    expect(domain.slides).to be_empty
    expect(domain.de_html_title).to eq "html title de"
    expect(domain.de_meta_description).to eq "meta desc de"
    expect(domain.de_page_heading).to eq "page heading de"
    expect(domain.de_content_md).to eq "# Hallo Welt!!"
    expect(domain.en_html_title).to eq "html title en"
    expect(domain.en_meta_description).to eq "meta desc en"
    expect(domain.en_page_heading).to eq "page heading en"
    expect(domain.en_content_md).to eq "# Hello World!"
    expect(domain.page_ids).to contain_exactly(page_a.id, page_b.id)
    expect(domain.villa_ids).to contain_exactly(villa_a.id)
    expect(domain.boat_ids).to contain_exactly(boat_b.id)
  end

  it "add slider images" do
    domain = create(:domain)
    visit edit_admin_domain_path(domain)

    expect(page).to have_content "Bilder Noch keine Inhalte hochgeladen."

    # upload
    attach_file "files[]", Rails.root.join("spec/fixtures/slide-03-xxs.jpg"),
      make_visible: undo_uppy_hide_file_input
    expect(page).to have_css ".media-list-item .recent-upload"

    # edit
    within find('[title="slide-03-xxs.jpg"]').tap(&:click) do
      click_on "inaktiv"
      expect(page).to have_no_content "inaktiv"
      expect(page).to have_content "aktiv"
    end

    slide = domain.slides.last
    expect(slide.filename).to eq "slide-03-xxs.jpg"
    expect(slide).to be_active
  end
end
