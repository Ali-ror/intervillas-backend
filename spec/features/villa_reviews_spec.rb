require "rails_helper"

RSpec.describe "Customer reviews" do
  let(:villa) {
    create :villa, :displayable, :bookable
  }
  let(:booking) { create_full_booking villa: villa }
  let(:customer) { booking.customer }
  let!(:review) { booking.inquiry.prepare_review }

  let(:message) { Faker::Lorem.paragraphs(number: 10).join("\n\n") }

  def select_stars(num)
    execute_script <<~JAVASCRIPT
      const el = document.getElementById("review_rating")
      el.value = #{num}
      el.dispatchEvent(new Event("change"))
    JAVASCRIPT
  end

  it "customer follows link", :js, vcr: { cassette_name: "booking/geocode" } do
    ratings = [3]

    visit edit_villa_review_path(villa, review.token)

    select_stars ratings[0]
    fill_in      "review_name",   with: customer.last_name
    fill_in      "review_city",   with: ""
    fill_in      "review_text",   with: message

    click_on "Bewertung abgeben"

    # noch nicht freigeschaltet
    expect(page).to have_content villa.name
    expect(page).to have_no_css "#ratings"
    expect(page).to have_no_content customer.last_name

    # freischalten
    Review.last.update published_at: DateTime.current

    # noch nicht genügend Bewertungen
    until villa.reload.show_reviews?
      visit villa_path(villa)
      expect(page).to have_content villa.name
      expect(page).to have_no_css "#ratings"
      expect(page).to have_no_content customer.last_name

      # weitere (freigeschaltete) Bewertung
      ratings << rand(1..5)
      create :review, :published, booking: create_full_booking(villa: villa), rating: ratings.last
    end

    visit villa_path(villa)
    expect(page).to have_content villa.name
    expect(page).to have_css "#ratings"

    page.scroll_to find("section", text: "Kundenmeinungen") # lazy loaded
    expect(page).to have_content customer.last_name

    schema = Mida::Document.new(page.html).items
    expect(schema[0].type).to eq "http://schema.org/LocalBusiness"

    rating = format("%0.1f", ratings.sum / ratings.size)

    expect(schema[0].properties).to be_kind_of Hash
    expect(schema[0].properties["aggregateRating"][0].type).to eq "http://schema.org/AggregateRating"
    expect(schema[0].properties["aggregateRating"][0].properties["ratingValue"][0]).to eq rating

    within "section", text: "Kundenmeinungen" do
      click_on "Hier finden Sie alle Kundenmeinungen."
    end
    expect(page).to have_current_path villa_reviews_path(villa), ignore_query: true
    expect(page).to have_content customer.last_name
  end
end
