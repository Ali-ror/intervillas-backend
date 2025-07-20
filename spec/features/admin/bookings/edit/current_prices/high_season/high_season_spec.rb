require "rails_helper"

RSpec.feature "Hochsaison", :js do
  include_context "as_admin"
  include_context "high season"

  shared_examples "listet Aufschläge" do
    scenario "listet Aufschläge" do
      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      expect_high_season_rents
    end
  end

  context "aktuelle Preise" do
    context "EUR" do
      include_context "editable booking", Currency::EUR, nights: 14

      include_examples "listet Aufschläge"
    end

    context "USD" do
      include_context "editable booking", Currency::USD, nights: 14

      include_examples "listet Aufschläge"
    end
  end
end
