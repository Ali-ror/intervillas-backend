require "rails_helper"

# Benutzer in der Admin-GUI anlegen.
RSpec.feature "Admin::Users::Creates" do
  include_context "as_admin"

  # Avoid simple passwords. Chrome 137+ shows a popup/warning when using a weak
  # password and block the UI thread (which makes interaction impossible).
  let(:new_password) { "*#{SecureRandom.uuid}!" }

  scenario "creating a User", :js do
    visit admin_root_path
    click_on "Kontakte"

    click_on "Benutzer-Zugänge"

    expect(page).to have_link "neuer Benutzer"
    click_on "neuer Benutzer"

    expect(page).to have_content "Benutzer hinzufügen"
    fill_in "E-Mail-Adresse", with: "foo@example.com"
    select "Anfragen, Buchungen, Objekte", from: "Freigabe-Level"
    click_on "Speichern"
    expect(page).to have_content \
      "Basis-Einstellungen für foo@example.com gespeichert."

    expect(page).to have_content <<~TEXT.squish
      Benutzer foo@example.com verfügt noch über kein Passwort.
      Benutzen Sie die "Passwort zurücksetzen"-Funktion,
      damit der Benutzer sein Passwort setzen kann.
    TEXT
    click_on "Passwort zurücksetzen"
    expect(page).to have_content "Anleitung zum Password-Reset wurde an foo@example.com versandt"

    sign_out admin
    open_email("foo@example.com")
    current_email.click_on "Change my password"

    fill_in "Neues Passwort", with: new_password
    fill_in "Neues Passwort bestätigen", with: new_password
    click_on "Passwort ändern"
    expect(page).to have_content "Ihr Passwort wurde geändert."

    fill_in "E-Mail-Adresse", with: "foo@example.com"
    fill_in "Passwort", with: new_password
    click_on "Einloggen"
    expect(page).to have_content "Erfolgreich angemeldet."

    within "header" do
      click_on "foo@example.com"
      click_on "Abmelden"
    end
    expect(page).to have_content "Erfolgreich abgemeldet."
  end
end
