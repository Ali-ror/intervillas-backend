require "rails_helper"

RSpec.feature "48 Stunden Frist", :js do
  let!(:villa) { create :villa, :bookable }

  def as_js_currency(value)
    # FIXME: the JS currency helper uses a different price formatting
    display_price value, separator: ",", delimiter: ".", format: "%n %u"
  end

  it "Anfrage soll nur bis zu 48 Stunden vor Reiseantritt möglich sein", :skip_on_xmas do
    today = Date.current
    visit villa_path(villa, start_date: today + 1.day, end_date: today + 8.days)

    # BUG: on Dec 19, the end_date should be at least start_date + 14.days
    date_range_picker.wait

    within_price_table do
      holiday_factor = VillaInquiry.minimum_booking_nights(today + 1.day, villa: villa) == 7 ? 1 : 2
      price          = villa.teaser_price * holiday_factor
      cleaning       = villa.villa_price.cleaning
      expect(page).to have_content "Mietpreis #{as_js_currency(price + cleaning)}"

      click_on "Details anzeigen"
      expect(page).to have_content "Grundpreis für 2 Pers. #{as_js_currency(price)}"
      expect(page).to have_content "Endreinigung #{as_js_currency(cleaning)}"
    end

    click_on "unverbindlich anfragen"
    expect(page).to have_content "muss in der Zukunft liegen (frühestens #{I18n.l(today + 2.days)})"
  end

  context "Anfrage existiert" do
    let!(:inquiry) { create_villa_inquiry(start_date: Date.tomorrow).inquiry }
    let(:customer_params) { attributes_for :customer }

    def book
      visit new_booking_path(token: inquiry.token)
      confirm_booking_request_on_page inquiry, customer_params: customer_params
    end

    it "Buchung soll nur bis zu 48 Stunden vor Reiseantritt möglich sein" do
      book
      expect(page).to have_content "mindestens 2 Tage nach der Buchung"
    end

    context "als Admin" do
      include_context "as_admin"

      it "soll Buchung trotzdem möglich sein #509" do
        book
        expect(page).to have_content "Vielen Dank für Ihre Buchung"
      end
    end
  end
end
