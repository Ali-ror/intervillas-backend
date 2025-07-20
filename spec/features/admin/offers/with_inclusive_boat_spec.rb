require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "mit Inklusiv-Boot" do
    feature "mit Inklusiv-Boot" do
      let!(:villa) { create :villa, :with_mandatory_boat, :bookable }

      scenario "erstellen" do
        navigate_to_inquiry_create
        enter_house_data curr, curr_values

        expect(page).to have_content villa.inclusive_boat.admin_display_name
        expect(page).to have_content "Inklusiv-Boot, kann nicht geändert werden"
      end
    end
  end

  context "EUR" do
    include_context "offers", Currency::EUR

    include_examples "mit Inklusiv-Boot"
  end

  context "USD" do
    include_context "offers", Currency::USD

    include_examples "mit Inklusiv-Boot"
  end
end
