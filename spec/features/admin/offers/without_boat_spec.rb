require "rails_helper"

RSpec.feature "Buchung bearbeiten", :js do
  include_context "as_admin"

  shared_examples "ohne Boot" do
    feature "ohne Boot" do
      let!(:villa) { create :villa, :bookable }

      scenario "erstellen" do
        navigate_to_inquiry_create
        enter_house_data curr, curr_values
      end
    end
  end

  context "EUR" do
    include_context "offers", Currency::EUR

    include_examples "ohne Boot"
  end

  context "USD" do
    include_context "offers", Currency::USD

    include_examples "ohne Boot"
  end
end
