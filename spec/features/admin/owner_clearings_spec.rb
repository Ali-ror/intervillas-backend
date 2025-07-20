require "rails_helper"

RSpec.describe "Eigentümerabrechnung", :js do
  include_context "as_admin"

  it "versenden" do
    owner = create_owner_clearing.owner
    owner.update! locale: "en"
    visit "/admin/clearings"
    click_on "versenden"
    expect(page).to have_content "Versand vorbereitet"

    expect(open_email(owner.emails.first).subject).to match(/Intervilla - Compiled Statements for \d{4}-\d{2}/)
  end

  # Statement                gross       net
  # Rent boat             € 162,61  € 152,69
  # Boat instruction      € 150,00  € 140,85
  # Total taxable boat    € 312,61  € 293,53
  #  6.5% Sales tax                 €  19,08
  #
  # Accounting               gross       net
  # Total excluding taxes           € 293,53
  # Admin Commission               -€  30,54
  # Payout                € 282,07  € 262,99
  context "Payout gross/net" do
    let!(:gross_billing) { create :boat_billing } # default
    let!(:net_billing) { create :boat_billing, :net_owner }

    it "displays correct payout" do
      visit "/admin/billings/#{net_billing.id}/edit#billings"
      expect(page).to have_content "Payout € 282,07 € 262,99"

      visit "/admin/clearings"
      within "tr", text: gross_billing.owner.display_name do
        expect(page).to have_content "€ 282,07"
      end

      within "tr", text: net_billing.owner.display_name do
        expect(page).to have_content "€ 262,99"
      end
    end
  end
end
