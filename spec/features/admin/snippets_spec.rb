require "rails_helper"

RSpec.describe "Text-Snippets", :js, :vcr do
  let!(:snippet) { create(:snippet, key: "villa_index_below_listing") }

  before do
    create(:villa, :with_descriptions, :bookable)

    sign_in_admin

    visit admin_root_path
    click_on "Sonstiges"
    click_on "Text-Schnipsel"
  end

  specify "editing a snippet updates the embedded place" do
    within "tr#snippet_#{snippet.id}" do
      click_on "bearbeiten"
    end

    fill_in "Text auf deutsch",  with: "# hallo welt\n\nbeispiel-text"
    fill_in "Text auf englisch", with: "# hello world\n\nsample text"

    click_on "Speichern"

    expect(page).to have_content "Text-Schnipsel '#{snippet.title}' erfolgreich gespeichert."

    visit de_villas_path
    within "#snippet-#{snippet.key}" do
      expect(page).to have_selector "h1", text: "hallo welt"
      expect(page).to have_selector "p", text: "beispiel-text"
    end

    visit en_villas_path
    within "#snippet-#{snippet.key}" do
      expect(page).to have_selector "h1", text: "hello world"
      expect(page).to have_selector "p", text: "sample text"
    end
  end

  specify "deleting a snippet disables embedding" do
    within "tr#snippet_#{snippet.id}" do
      click_on "löschen"
    end

    expect(page).to have_content "Text-Schnipsel '#{snippet.title}' wurde erfolgreich gelöscht."

    visit de_villas_path
    expect(page).to     have_selector "form.villa-facet-search"
    expect(page).not_to have_selector "#snippet-#{snippet.key}"

    visit en_villas_path
    expect(page).to     have_selector "form.villa-facet-search"
    expect(page).not_to have_selector "#snippet-#{snippet.key}"
  end
end
