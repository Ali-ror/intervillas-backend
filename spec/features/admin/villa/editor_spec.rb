require "rails_helper"

RSpec.describe "VillaEditor", :js, :vcr do
  include_context "as_admin"

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

  let!(:contact)        { create :contact }
  let!(:optional_boats) { create_list :boat, 3, :active }

  before { restore_tags! }

  # Navigates to a specific tab and waits for the page title to match the
  # expectation. `name_and_title` must be a 1-entry Hash, where the key
  # matches a link in the nav bar, and the value matches the page title.
  #
  # It yields for the sole reason to have a collapsable source code region.
  def villa_edit_tab(name_and_title = {})
    name, title = name_and_title.first
    within("aside") { click_on name }
    expect(page).to have_css ".page-header", text: title
    yield
  end

  def within_element_containing(elem, subel, text:, &block)
    within :xpath, %<//#{elem}[#{subel}[contains(text(), "#{text}")]]>, &block
  end

  def _toggle_tag(label_text, strict: false)
    label = find("label", text: label_text, visible: false)
    yield label.find("input[type='checkbox']", visible: false) if strict
    label.click
  end

  def check_tag(label_text, strict: false)
    _toggle_tag(label_text, strict: strict) do |input|
      raise RangeError, "tag #{label_text} already checked" if input.checked?
    end
  end

  def uncheck_tag(_label, strict: false)
    _toggle_tag(label_text, strict: strict) do |input|
      raise RangeError, "tag #{label_text} already unchecked" unless input.checked?
    end
  end

  def expect_and_dismiss_flash(message)
    expect(page).to have_css ".alert-success", text: message
    click_on_until ".alert-success a.close" do
      page.has_no_content? message, wait: 0.2
    end
  end

  context "create villa" do
    it "saves a new villa" do
      visit admin_root_path
      click_on "Objekte"
      click_on "Villen"
      click_on "Neue Villa anlegen"

      expect(page).to have_no_content "Bitte warten, Daten werden geladen"

      within "aside" do
        within "li.active" do
          expect(page).to have_link "Villa-Details"
        end
        expect(page).to have_no_link "Merkmale"
        expect(page).to have_no_link "Preise"
        expect(page).to have_no_link "Fotos"
        expect(page).to have_no_link "Touren v1"
        expect(page).to have_no_link "Touren v2"
        expect(page).to have_no_link "Boote"
        expect(page).to have_no_link "Bewertungen"

        expect(page).to have_content "Weitere Einstellungen sind erst nach dem Speichern möglich."
      end

      new_phone_number = Faker::PhoneNumber.phone_number
      expect {
        villa_edit_tab "Villa-Details" => "Details anlegen" do
          click_on "Speichern"
          expect(page).to have_css ".alert-warning", text: "Speichern nicht möglich: das Formular enthält noch Fehler"

          check "aktiv?"
          check "intervillas-florida.com"

          fill_in "Name", with: "Villa Supa Dupa"
          fill_in "Wohnfläche", with: 350
          select "Süden", from: "Ausrichtung Pool"
          ui_select contact.name, from: "Hausverwaltung"
          ui_select contact.name, from: "Eigentümer"
          fill_in "Safe-Code", with: "12345"
          fill_in "Telefonnummer", with: new_phone_number
          fill_in "Mindestbuchungsdauer", with: 7

          click_on "Adresse suchen"
          fill_in "Adresse suchen", with: "5608 SW 9th Ave, 33914, Cape Coral, FL"
          click_on "Suchen"
          click_on "Adresse übernehmen"

          expect(page).to have_content "Keine externen Kalender definiert."
          click_on "Kalender hinzufügen"
          fill_in "URL", with: "https://caldav.example.com/?id=qwertz"

          expect {
            click_on "Speichern"
            expect_and_dismiss_flash "Villa Supa Dupa erfolgreich erstellt"
          }.to change { current_url }.from(%r{/admin/villas/new#/}).to(%r{/admin/villas/\d+/edit#/})
        end
      }.to change(Villa, :count).by(1).and(
        change(Calendar, :count).by(1),
      )

      villa = Villa.find_by(name: "Villa Supa Dupa")
      expect(villa.name).to eq "Villa Supa Dupa"
      expect(villa.active?).to be true
      expect(villa.pool_orientation).to eq "s"
      expect(villa.living_area).to be 350
      expect(villa.owner_id).to be contact.id
      expect(villa.manager_id).to be contact.id
      expect(villa.phone).to eq new_phone_number
      expect(villa.street).to eq "5608 SW 9th Ave"
      expect(villa.locality).to eq "Cape Coral"
      expect(villa.region).to eq "FL"
      expect(villa.postal_code).to eq "33914"
      expect(villa.country).to eq "US"

      # from this point on, it's the same as editing an existing villa (see next spec)
    end
  end

  context "edit villa" do
    let!(:villa) { create :villa, :with_mandatory_boat, no_tags: true }

    it "updates its attributes" do
      visit admin_root_path
      click_on "Objekte"
      click_on "Villen"
      within "tr", text: villa.name do
        click_on "bearbeiten"
      end

      expect(page).to have_no_content "Bitte warten, Daten werden geladen"

      within "aside" do
        within "li.active" do
          expect(page).to have_link "Villa-Details"
        end
        expect(page).to have_link "Merkmale"
        expect(page).to have_link "Preise"
        expect(page).to have_link "Fotos"
        expect(page).to have_link "Touren v1"
        expect(page).to have_link "Touren v2"
        expect(page).to have_link "Boote"
        expect(page).to have_link "Bewertungen"
      end

      new_phone_number = Faker::PhoneNumber.phone_number
      expect {
        villa_edit_tab "Villa-Details" => "Details bearbeiten" do
          click_on "Speichern"
          expect(page).to have_css ".alert-warning", text: "Speichern nicht möglich: das Formular enthält noch Fehler"

          fill_in "Name", with: "Villa Supa Dupa"
          ui_select contact.name, from: "Hausverwaltung"
          ui_select contact.name, from: "Eigentümer"
          fill_in "Telefonnummer", with: new_phone_number

          click_on "Adresse suchen"
          fill_in "Adresse suchen", with: "5608 SW 9th Ave, 33914, Cape Coral, FL"
          click_on "Suchen"
          click_on "Adresse übernehmen"

          click_on "Speichern"
          expect_and_dismiss_flash "Villa Supa Dupa erfolgreich gespeichert"
          villa.reload
        end
      }.to change(villa, :name).to("Villa Supa Dupa")
        .and change(villa, :owner_id).to(contact.id)
        .and change(villa, :manager_id).to(contact.id)
        .and change(villa, :phone).to(new_phone_number)
        .and change(villa, :street).to("5608 SW 9th Ave")
        .and change(villa, :locality).to("Cape Coral")
        .and change(villa, :region).to("FL")
        .and change(villa, :postal_code).to("33914")
        .and change(villa, :country).to("US")

      villa_edit_tab "Merkmale" => "Merkmale bearbeiten" do
        within_element_containing :fieldset, :legend, text: "Villa Specials" do
          check_tag "Boot"
          check_tag "Fahrrad"
          check_tag "Aussenwhirlpool/Spa"

          fill_in "Kopftext auf deutsch", with: "mein Kopftext"
          fill_in "Kopftext auf englisch", with: "my header text"
          fill_in "Intro Text auf deutsch", with: "mein Kacheltext"
          fill_in "Intro Text auf englisch", with: "my teaser text"
          fill_in "Beschreibung auf deutsch", with: "meine Objekt-Beschreibung"
          fill_in "Beschreibung auf englisch", with: "my object description"
        end

        within_element_containing :fieldset, :legend, text: "Schlafzimmer" do
          3.times do
            click_on "Schlafzimmer hinzufügen"
            sleep 0.1
          end

          select "Schlafzimmer", from: "Schlafzimmer #1: Typ"
          fill_in "Schlafzimmer #1: Anzahl Schlafmöglichkeiten", with: 2
          fill_in "Schlafzimmer #1: Kingsize (Doppelbett gross)", with: 1

          select "Schlafzimmer", from: "Schlafzimmer #2: Typ"
          fill_in "Schlafzimmer #2: Anzahl Schlafmöglichkeiten", with: 2
          fill_in "Schlafzimmer #2: Queensize (Doppelbett normal)", with: 1

          select "Schlafzimmer", from: "Schlafzimmer #3: Typ"
          fill_in "Schlafzimmer #3: Anzahl Schlafmöglichkeiten", with: 1
          fill_in "Schlafzimmer #3: Schlafsofas", with: 1
        end

        within_element_containing :fieldset, :legend, text: "Badezimmer" do
          2.times do
            click_on "Badezimmer hinzufügen"
            sleep 0.1
          end

          select "Vollbad", from: "Badezimmer #1: Typ"
          check_tag "Badezimmer #1: WC"
          check_tag "Badezimmer #1: Dusche"
          check_tag "Badezimmer #1: Badewanne"
          check_tag "Badezimmer #1: Handtücher"
          check_tag "Badezimmer #1: Föhn"

          select "Gäste-WC", from: "Badezimmer #2: Typ"
          check_tag "Badezimmer #2: WC"
        end

        # check whether dirty-tracking intercepts the navigation attempt
        within("aside") { click_on "Preise" }
        within ".well.well-sm", text: "Warnung: Ungespeicherte Änderungen gefunden." do
          click_on "speichern"
        end
        expect_and_dismiss_flash "Villa Supa Dupa erfolgreich gespeichert"

        villa.reload
        desc = villa.descriptions.reload
        I18n.with_locale(:de) do
          expect(desc.get(:header).text).to eq "mein Kopftext"
          expect(desc.get(:teaser).text).to eq "mein Kacheltext"
          expect(desc.get(:description).text).to eq "meine Objekt-Beschreibung"
          expect(desc.get(:theme).text).to be_blank
        end

        I18n.with_locale(:en) do
          expect(desc.get(:header).text).to eq "my header text"
          expect(desc.get(:teaser).text).to eq "my teaser text"
          expect(desc.get(:description).text).to eq "my object description"
          expect(desc.get(:theme).text).to be_blank
        end

        expect(villa.amount_of_tag("boot",    "highlights")).to be 1
        expect(villa.amount_of_tag("fahrrad", "highlights")).to be 1
        expect(villa.amount_of_tag("spa",     "highlights")).to be 1

        expect(villa.bedrooms_count).to be 3
        expect(villa.beds_count).to be 5
        rooms = villa.bedrooms.sort_by(&:id) # the order somehow gets messed up
        expect(rooms[0].amount_of_tag("franzoesischbettgross", "bedrooms")).to be 1
        expect(rooms[1].amount_of_tag("franzoesischbettklein", "bedrooms")).to be 1
        expect(rooms[2].amount_of_tag("schlafsofa",            "bedrooms")).to be 1

        expect(villa.bathrooms_count).to be 1
        expect(villa.wcs_count).to be 2
        rooms = villa.bathrooms.sort_by(&:id) # again, reorder rooms
        expect(rooms[0].amount_of_tag("wc",          "bathrooms")).to be 1
        expect(rooms[0].amount_of_tag("dusche",      "bathrooms")).to be 1
        expect(rooms[0].amount_of_tag("badewanne",   "bathrooms")).to be 1
        expect(rooms[0].amount_of_tag("handtuecher", "bathrooms")).to be 1
        expect(rooms[0].amount_of_tag("foen",        "bathrooms")).to be 1
        expect(rooms[1].amount_of_tag("wc",          "bathrooms")).to be 1
      end

      villa_edit_tab "Preise" => "Preise bearbeiten" do
        expect(page).to have_content "Personen-Preise"
        select "pro Person/pro Nacht", from: "Abrechnungsmodus"

        curr_values = OdsTestValues.for(Currency::EUR)
        {
          base_rate:         "Grundpreis für 2 Pers. (EUR)",
          additional_adult:  "weitere Person (EUR)",
          children_under_6:  "Kind bis 6 J. (EUR)",
          children_under_12: "Kind bis 12 J. (EUR)",
          deposit:           "Kaution (EUR)",
          cleaning:          "Reinigung (EUR)",
        }.each do |category, field|
          case category
          when :children_under_6  then click_on("Kind bis 6 J. aktivieren")
          when :children_under_12 then click_on("Kind bis 12 J. aktivieren")
          end

          fill_in field, with: curr_values.lookup_category(category, format: false)
        end

        within ".panel", text: "Weihnachten (25.+26. Dezember)" do
          click_on "hinzufügen"
          fill_in "Aufschlag",   with: 25
          fill_in "Tage vorher", with: 2
          fill_in "Tage danach", with: 14
        end

        click_on "Speichern"
        expect_and_dismiss_flash "Villa Supa Dupa erfolgreich gespeichert"

        villa_price = villa.villa_price_eur.reload

        expect(villa_price.base_rate).to eq curr_values.lookup_category(:base_rate, format: false)
        expect(villa_price.additional_adult).to eq curr_values.lookup_category(:additional_adult, format: false)
        expect(villa_price.children_under_6).to eq curr_values.lookup_category(:children_under_6, format: false)
        expect(villa_price.children_under_12).to eq curr_values.lookup_category(:children_under_12, format: false)
        expect(villa_price.cleaning).to eq curr_values.lookup_category(:cleaning, format: false)
        expect(villa_price.deposit).to eq curr_values.lookup_category(:deposit, format: false)

        hd = villa.holiday_discounts.reload
        expect(hd.size).to be 1
        expect(hd[0]).to have_attributes(description: "christmas", days_before: 2, days_after: 14, percent: 25)
      end

      villa_edit_tab "Fotos" => "Medien bearbeiten" do
        expect(page).to have_content "Bilder Noch keine Inhalte hochgeladen"

        # upload
        attach_file "files[]", Rails.root.join("spec/fixtures/pool.jpg"),
          make_visible: undo_uppy_hide_file_input
        expect(page).to have_css ".media-list-item .recent-upload"

        medium = Media::Image.last
        expect(medium).to be_present

        # edit
        find('[title="pool.jpg"]').click
        expect(page).to have_field "Dateiname", with: "pool"
        fill_in "Dateiname", with: "pool-picture"
        fill_in "Beschreibung (deutsch)", with: "tolles Foto"
        fill_in "Beschreibung (englisch)", with: "great picture"
        expect(page).to have_content "ungespeicherte Änderungen"
        click_on "speichern"
        expect(page).to have_content "Gespeichert!"

        medium.reload
        expect(medium.filename).to eq "pool-picture.jpg"
        expect(medium.de_description).to eq "tolles Foto"
        expect(medium.en_description).to eq "great picture"

        # destroy
        click_on "löschen"
        accept_confirm("Dies kann nicht rückgängig gemacht werden. Fortfahren?")
        expect(page).to have_content "Noch keine Inhalte hochgeladen"

        expect { medium.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      villa_edit_tab "Touren v1" => "Medien bearbeiten" do
        # skipping. basically identical to Touren v2
        expect(page).to have_content "Touren v1 Noch keine Inhalte hochgeladen"
      end

      villa_edit_tab "Touren v2" => "Medien bearbeiten" do
        expect(page).to have_content "Touren v2 Noch keine Inhalte hochgeladen"

        # upload
        attach_file "files[]", Rails.root.join("spec/fixtures/pool-360.jpg"),
          make_visible: undo_uppy_hide_file_input
        expect(page).to have_css ".media-list-item .recent-upload"

        medium = Media::Pannellum.last
        expect(medium).to be_present

        # edit
        find('[title="pool-360.jpg"]').click
        expect(page).to have_field "Dateiname", with: "pool-360"
        fill_in "Dateiname", with: "panorama"
        fill_in "Beschreibung (deutsch)", with: "tolle 360-Grad-Ansicht"
        fill_in "Beschreibung (englisch)", with: "great 360 degree view"
        expect(page).to have_content "ungespeicherte Änderungen"
        click_on "speichern"
        expect(page).to have_content "Gespeichert!"

        medium.reload
        expect(medium.filename).to eq "panorama.jpg"
        expect(medium.de_description).to eq "tolle 360-Grad-Ansicht"
        expect(medium.en_description).to eq "great 360 degree view"

        # destroy
        click_on "löschen"
        accept_confirm("Dies kann nicht rückgängig gemacht werden. Fortfahren?")
        expect(page).to have_content "Noch keine Inhalte hochgeladen"

        expect { medium.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      inclusive_boat = villa.inclusive_boat
      expect {
        villa_edit_tab "Boote" => "Boote bearbeiten" do
          choose "Boot optional buchbar"
          check optional_boats[0].admin_display_name
          check optional_boats[2].admin_display_name

          click_on "Speichern"
          expect_and_dismiss_flash "Villa Supa Dupa erfolgreich gespeichert"
          villa.reload
        end
      }.to change(villa, :optional_boat_ids).from([]).to([optional_boats[0].id, optional_boats[2].id])

      expect(inclusive_boat.reload.villa_id).to be_nil if inclusive_boat

      villa_edit_tab "Bewertungen" => "Bewertungen bearbeiten" do
        expect(page).to have_content "Noch keine Bewertungen vorhanden"
      end
    end

    it "changes pricing mode" do
      visit admin_root_path
      click_on "Objekte"
      click_on "Villen"
      within "tr", text: villa.name do
        click_on "bearbeiten"
      end

      expect(page).to have_no_content "Bitte warten, Daten werden geladen"

      villa_edit_tab "Preise" => "Preise bearbeiten" do
        expect(page).to have_content "Personen-Preise"

        select "Wochenpreis", from: "Abrechnungsmodus"
        choose "EUR und USD"

        {
          "pro Übernachtung" => [100,  123],
          "Kaution"          => [1000, 1234],
          "Reinigung"        => [200,  235],
        }.each do |field, (eur, usd)|
          fill_in "#{field} (EUR)", with: eur
          fill_in "#{field} (USD, inkl. KK-Gebühr)", with: usd
        end

        click_on "Speichern"
        expect_and_dismiss_flash "#{villa.name} erfolgreich gespeichert"

        expect(villa.reload.villa_prices).to include(
          have_attributes(
            currency:          "EUR",
            base_rate:         100,
            additional_adult:  0,
            children_under_6:  nil,
            children_under_12: nil,
            cleaning:          200,
            deposit:           1000,
          ),
          have_attributes(
            currency:          "USD",
            base_rate:         123,
            additional_adult:  0,
            children_under_6:  nil,
            children_under_12: nil,
            cleaning:          235,
            deposit:           1234,
          ),
        )
      end
    end
  end
end
