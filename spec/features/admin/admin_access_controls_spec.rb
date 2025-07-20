require "rails_helper"

# Benutzer, Kontakte und Objekte erzeugen und prüfen, ob die Benutzer nur auf
# ihre eigenen Objekte Zugriff haben.
RSpec.feature "Admin::AccessControls" do
  let(:contacts) { create_list :contact, 2 }
  let(:villas) { create_list :villa, 2 }
  let(:boats) { create_list :boat, 2 }
  let(:users) { create_list :user, 2, :with_password }

  before do
    contacts.each.with_index do |contact, index|
      contact.owned_villas << villas[index]
      contact.owned_boats << boats[index]
      contact.users << users[index]
    end
  end

  scenario "Benutzer 1 sieht eigene Villen" do
    sign_in users[0]
    visit user_root_path

    expect(page).to have_link villas[0].admin_display_name
    expect(page).to have_no_link villas[1].admin_display_name

    expect(page).to have_link boats[0].admin_display_name
    expect(page).to have_no_link boats[1].admin_display_name
  end
end
