require "rails_helper"

RSpec.feature "new booking without boat", :js, vcr: { cassette_name: "admin_villa/geocode" } do
  include_context "as_admin"

  def creates_booking_helper
    inquiry = create_booking_request(villa_inquiry_params) {
      within_price_table do
        click_on "Details anzeigen"
      end
      yield
    }
    create_customer(newsletter: true)
    expect(page).to have_content I18n.t("bookings.create.vielen_dank")
    inquiry.reload
    expect(inquiry.customer.newsletter).to be true
    expect(inquiry.customer.phone).not_to be_blank
    confirm_booking_request(inquiry, customer_params: customer_params)
    expect(inquiry.currency).to eq curr

    # Preise in Emails sollen auch in der gebuchten Währung sein
    expect(open_email(customer_params[:email])).to have_content Currency.symbol(curr)

    ci = inquiry.clearing_items
    expect(ci.where("category like 'base_rate%'")).to be_exist
    expect(ci.where("category like 'children_under_12%'")).to(be_exist) if villa_inquiry_params[:children_under_12]
    expect(ci.where(category: "weekly_rate")).not_to be_exist
  end

  shared_examples "without boat" do
    let!(:villa) { create :villa, :with_descriptions, :bookable }
    let(:villa_inquiry_params) { attributes_for :villa_inquiry, adults: 3, children_under_12: 1 }

    it "creates booking" do
      creates_booking_helper {
        expect_price_breakdown_lookup("Grundpreis für 2 Pers.", "14 Nächte 2 Erwachsene")
        expect_price_breakdown_lookup("weitere Person(en)",     "14 Nächte 1 weitere Person(en)")
        expect_price_breakdown_lookup("Kinder bis 12",          "14 Nächte 1 Kinder bis 12 J.")
        expect_price_breakdown_lookup("Endreinigung")
      }
    end
  end

  shared_examples "without boat and min 3 people" do
    let(:villa) { create :villa, :with_descriptions, :bookable }
    let(:villa_inquiry_params) { attributes_for :villa_inquiry, adults: 4, children_under_12: nil }

    before do
      villa.villa_prices.each { |vp| vp.update! children_under_12: nil, children_under_6: nil }
      villa.update! minimum_people: 3
    end

    it "creates booking" do
      creates_booking_helper {
        within_price_table do
          expect(page).not_to have_content "Kinder bis 12"
        end
        expect_price_breakdown_lookup("Grundpreis für 3 Pers.", "14 Nächte 2 Erwachsene")
        expect_price_breakdown_lookup("weitere Person(en)",     "14 Nächte 1 weitere Person(en)")
        expect_price_breakdown_lookup("Endreinigung")
      }
    end
  end

  context "in EUR" do
    include_context "prepare new booking", Currency::EUR
    it_behaves_like "without boat"
    it_behaves_like "without boat and min 3 people"
  end

  context "in USD" do
    include_context "prepare new booking", Currency::USD
    it_behaves_like "without boat"
    it_behaves_like "without boat and min 3 people"
  end
end
