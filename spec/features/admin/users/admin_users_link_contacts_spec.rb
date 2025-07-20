require "rails_helper"

RSpec.feature "Admin::Users::LinkContacts", :js do
  include_context "as_admin"

  let(:villa) { create :villa }
  let(:boat) { create :boat }
  let!(:contact) { create :contact }
  let!(:user) { create :user, :with_password }

  before do
    contact.owned_villas << villa
    contact.owned_boats << boat
  end

  scenario "Admin links Contact to User", :js do
    visit admin_root_path
    click_on "Kontakte"
    click_on "Benutzer-Zugänge"

    within "tr", text: user.email do
      click_link "bearbeiten"
    end

    within ".js-main-nav" do
      click_link "Kontakte"
    end

    check contact.name
    click_on "speichern"

    # user sieht alle villen von contact
    expect(contact.rentables).not_to be_empty

    using_ephemeral_session "other user" do
      visit user_root_path
      fill_in "E-Mail-Adresse", with: user.email
      fill_in "Passwort",       with: user.password
      click_on "Einloggen"

      expect(page).to have_content "Häuser"

      contact.rentables.map(&:rentable).each do |rentable|
        expect(page).to have_link rentable.admin_display_name
      end
    end
  end
end
