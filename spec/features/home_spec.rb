require "rails_helper"

RSpec.describe "Home page" do
  before do
    create :villa, :bookable
  end

  it "preloads images" do
    visit "/"

    [
      "(min-width: 1440px)",
      "(min-width: 1080px) and (max-width: 1440px)",
      "(min-width: 768px) and (max-width: 1080px)",
      "(max-width: 768px)",
    ].each do |media|
      expect(page).to have_css %(head link[rel="preload"][as="image"][media="#{media}"]), visible: :hidden
    end
  end

  # XXX: can be removed after corporate_switch_date
  describe "Impressum when transitioning from GmbH to Corp." do
    context "GmbH" do
      travel_to_gmbh_era! offset: 1.second

      it "renders correct address" do
        visit "/"
        within "footer" do
          expect(page).to have_content "Intervilla GmbH Rebenstr. 34 8309 Nürensdorf Schweiz"
        end
      end
    end

    context "Corp" do
      travel_to_corp_era! offset: 0

      it "renders correct address" do
        visit "/"
        within "footer" do
          expect(page).to have_content "Intervilla Corp. 4929 SW 26th Ave Cape Coral, FL 33914, USA"
        end
      end
    end
  end
end
