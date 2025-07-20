require "rails_helper"

RSpec.feature "second factor authentication", :js do
  context "for admins" do
    let(:user) { create :user, :with_password, admin: true }

    it "is enforced" do
      visit admin_users_path
      fill_in "E-Mail-Adresse", with: user.email
      fill_in "Passwort", with: user.password
      click_on "Einloggen"

      expect(page).to have_content "Sie haben noch keine Zwei-Faktor-Authentifizierung eingerichtet."
    end

    it "is enforced until completed" do
      user.prepare_otp!

      visit admin_users_path
      fill_in "E-Mail-Adresse", with: user.email
      fill_in "Passwort", with: user.password
      click_on "Einloggen"

      expect(page).to have_content "Sie haben noch keine Zwei-Faktor-Authentifizierung eingerichtet."
    end

    it "is required on login" do
      user.prepare_otp!
      user.enable_otp! user.current_otp

      visit admin_users_path
      fill_in "E-Mail-Adresse", with: user.email
      fill_in "Passwort", with: user.password
      click_on "Einloggen"

      # reset consumed timestep (from enable_otp!), otherwise we'd need to wait 30s
      user.update! consumed_timestep: nil

      expect(page).to have_content "Sicherheitsabfrage"
      fill_in "Einmal-Code", with: user.current_otp
      click_on "Bestätigen"

      expect(page).to have_content "Erfolgreich angemeldet"
      expect(page).to have_content "Hinweise zu den Berechtigungen"
    end
  end

  context "setup" do
    let(:user) { create :user, :with_password }

    it "involved scanning a QR code" do
      visit admin_villas_path

      fill_in "E-Mail-Adresse", with: user.email
      fill_in "Passwort", with: user.password
      click_on "Einloggen"

      expect(page).to have_content "Erfolgreich angemeldet"

      within "header" do
        click_on user.email
        click_on "Zwei-Faktor-Authentifizierung"
      end

      expect(page).to have_content "Sie haben derzeit noch keine Zwei-Faktor-Authentisierung eingerichtet."
      click_on "Weiter"

      expect(page).to have_content "Die Zwei-Faktor-Authentisierung wurde vorbereitet, ist aber noch nicht abschließend eingerichtet."
      fill_in "Code zur Bestätigung", with: user.reload.current_otp
      click_on "Weiter"

      expect(page).to have_content "Die Zwei-Faktor-Authentifizierung wurde erfolgreich eingerichtet."
      expect(page).to have_content "Bitte lesen Sie die nachfolgenden Hinweise gründlich."
      expect(page).to have_content "Wichtig: Backup-Codes"
      click_on "OK"

      expect(page).to have_content "Die Zwei-Faktor-Authentisierung ist derzeit aktiv."
      expect(page).to have_content "Sie werden bei jedem Login nach einem OTP gefragt."
    end
  end
end
