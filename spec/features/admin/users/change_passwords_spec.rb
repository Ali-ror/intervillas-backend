require "rails_helper"

RSpec.feature "users change passwords", :js do
  def create_user(**params)
    create :user, **params.merge(
      email:     "foo@example.com",
      password:  "password",
      locked_at: nil,
    )
  end

  scenario "password reuse is disallowed" do
    user = create_user(previous_passwords: [
      # this works until User#password_digest is overridden
      Devise::Encryptor.digest(User, "previouspassword"),
    ])

    sign_in user
    visit admin_edit_user_registration_path

    # reuse current password
    fill_in "Neues Passwort", with: user.password
    fill_in "Neues Passwort bestätigen", with: user.password
    fill_in "Aktuelles Passwort", with: user.password
    click_on "Passwort ändern"
    expect(page).to have_content "wurde in der Vergangenheit schon einmal verwendet"

    # reuse a previous password
    fill_in "Neues Passwort", with: "previouspassword"
    fill_in "Neues Passwort bestätigen", with: "previouspassword"
    fill_in "Aktuelles Passwort", with: user.password
    click_on "Passwort ändern"
    expect(page).to have_content "wurde in der Vergangenheit schon einmal verwendet"

    # new password
    fill_in "Neues Passwort", with: "password2"
    fill_in "Neues Passwort bestätigen", with: "password2"
    fill_in "Aktuelles Passwort", with: "password"
    click_on "Passwort ändern"
    expect(page).to have_content "Ihre Daten wurden aktualisiert"
  end

  scenario "forced on password expiry" do
    user = create_user(password_expires_at: 1.second.ago)

    visit admin_root_path
    fill_in "E-Mail-Adresse", with: user.email
    fill_in "Passwort", with: user.password
    click_on "Einloggen"

    expect(page).to have_content "Erfolgreich angemeldet."
    expect(page).to have_content "Ihr Password ist abgelaufen, bitte legen Sie ein neues fest."
  end
end
