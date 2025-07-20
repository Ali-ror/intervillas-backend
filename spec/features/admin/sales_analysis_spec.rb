require "rails_helper"

RSpec.feature "Umsatz Analyse", :js do
  include_context "as_admin"

  def utc_date(year, month, date)
    Date.new(year, month, date).in_time_zone("UTC")
  end

  before do
    create_full_booking(start_date: utc_date(2018, 1, 1)).update created_at: utc_date(2018, 1, 1)
    create_full_booking(start_date: utc_date(2018, 1, 1), currency: Currency::USD).update created_at: utc_date(2018, 1, 1)
    create_full_booking(start_date: utc_date(2019, 1, 1), end_date: utc_date(2019, 1, 15)).update created_at: utc_date(2019, 1, 1)
    create_full_booking(start_date: utc_date(2019, 1, 1), end_date: utc_date(2019, 1, 15), currency: Currency::USD).update created_at: utc_date(2019, 1, 1)
  end

  scenario do
    visit "/admin/sales"
    expect(page).to have_content "Bitte das Datum auswählen, bis zu dem die Auswertung durchgeführt werden soll."
    date_range_picker.select_dates "2019-07-18"

    expect(page).to have_css "h1", text: "Umsatzanalyse 2018/2019 bis 18. Juli"
    expect(page).to have_content "1. Jan. - 18. Juli 2018 2019 Veränderung"
    expect(page).to have_content "Brutto EUR 1.120,00 € 2.240,00 € 1.120,00 €"
    expect(page).to have_content "Brutto USD 1.491,00 $ 2.982,00 $ 1.491,00 $"
    expect(page).to have_content "Netto EUR 1.009,01 € 2.008,97 € 999,96 €"
    expect(page).to have_content "Netto USD 1.343,24 $ 2.674,44 $ 1.331,20 $"
  end
end
