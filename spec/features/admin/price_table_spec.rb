require "rails_helper"

RSpec.describe "Preistabelle im Admin-Bereich", :js do
  include_context "as_admin"

  def wait_for_inquiry_editor
    # Die Vue-Komponente feuert einen AJAX-Request ab, nachdem sie gemountet
    # wurde. Vermeidet Race-Condition zwischen database_cleaner und dem
    # Beantworten des Requests im Controller
    expect(page).not_to have_content "Bitte warten"
  end

  describe "mit Weihnachtsaufschlag" do
    let!(:inquiry) { create(:inquiry, :with_villa_inquiry) }

    before do
      create(:clearing_item, inquiry: inquiry, villa_id: inquiry.villa.id, start_date: "2017-12-24", end_date: "2018-01-03", category: "adults_christmas")
      create(:clearing_item, inquiry: inquiry, villa_id: inquiry.villa.id, start_date: "2017-12-24", end_date: "2018-01-03", category: "adults_easter")
      create(:clearing_item, inquiry: inquiry, villa_id: inquiry.villa.id, start_date: "2017-12-24", end_date: "2018-01-03", category: "adults_special")
    end

    it do
      visit edit_admin_inquiry_path(inquiry.id)

      wait_for_inquiry_editor
      expect(page).to have_content "10 Nächte 1 + Weihnachten"
      expect(page).to have_content "10 Nächte 1 + Ostern"
      expect(page).to have_content "10 Nächte 1 - Last Minute"
    end
  end

  describe "mit Hochsaison-Aufschlag" do
    let!(:villa_inquiry) { create :villa_inquiry, :high_season }

    it do
      discount_finder = DiscountFinder.new(villa_inquiry.villa,
        villa_inquiry.start_date,
        villa_inquiry.end_date,
        villa_inquiry.created_at)

      expect(discount_finder.discounts).to include have_attributes(subject: "high_season")
      expect(villa_inquiry.clearing_items.reload).to include have_attributes(category: "base_rate_high_season")

      visit edit_admin_inquiry_path(villa_inquiry.inquiry_id)

      wait_for_inquiry_editor
      expect(page).to have_content "14 Nächte + Hochsaison"
    end
  end
end
