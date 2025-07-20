require "rails_helper"

RSpec.feature "Kreditkartengebühr für Buchungen in USD", :js do
  include_context "as_admin"
  include ActiveSupport::NumberHelper

  let!(:villa) { create :villa, :bookable }

  delegate :villa_price, to: :villa

  it do
    visit "/admin/settings"
    within ".panel", text: "Kreditkartengebühr für Buchungen in USD" do
      expect(page).to have_field "Prozentsatz", with: 3.5
    end

    click_link "Webseite"
    click_link "Preise in US$ anzeigen"

    within "header" do
      click_link "Ferienhaus Cape Coral"
    end

    base_price    = villa_price.base_rate
    base_usd      = base_price * ::Setting.exchange_rate_usd
    base_usd_feed = base_usd * 1.035

    teaser_price = 7 * base_usd_feed.value.ceil
    expect(page).to have_content number_to_delimited(teaser_price, delimiter: "'", seperator: ",").strip # 1.035 ~ 3.5 %
  end
end
