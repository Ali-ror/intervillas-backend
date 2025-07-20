require "rails_helper"

RSpec.feature "Admin::Users::Merges" do
  include_context "as_admin"

  # Zwei vorhandene Benutzer-Accounts zusammenführen
  let!(:users) { create_list :user, 2 }

  scenario "merges two users", :js do
    visit admin_root_path
    click_on "Kontakte"
    click_on "Benutzer-Zugänge"
    click_on "Inaktiv"

    within "tr", text: users[0].email do
      click_on "bearbeiten"
    end

    expect(page).to have_content "Benutzer bearbeiten"
    click_on "Benutzer zusammenführen"

    expect(page).to have_content \
      "Informationen zum Zusammenführen von Benutzern"
    ui_select users[1].email, from: "Quelle"
    click_on "zusammenführen"

    expect(page).to have_content <<~TEXT.squish
      Benutzer #{users[1].email} mit #{users[0].email}
      zusammengeführt (und #{users[1].email} gelöscht).
    TEXT
  end
end
