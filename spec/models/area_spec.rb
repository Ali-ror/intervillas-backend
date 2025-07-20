require "rails_helper"

RSpec.describe Area, vcr: { cassette_name: "villa/geocode" } do
  %w[villa category].each do |col|
    it { is_expected.to validate_presence_of col }
    it { is_expected.to belong_to col.to_sym }
  end

  %w[taggings tags].each do |col|
    it { is_expected.to have_many(col.to_sym) }
  end

  describe "Rooms and Tags" do
    subject(:villa) { create(:villa) }

    let!(:category1) { create(:category, :bedrooms) }
    let!(:category2) { create(:category, :bathrooms) }

    it "should be able to get tagged with beds" do
      bedroom1 = create :area, villa: villa, category: category1, subtype: "schlafzimmer", beds_count: 3
      bedroom1.tag_with("doppelbett", "bedrooms", 1)
      bedroom1.tag_with("einzelbett", "bedrooms", 1)
      bedroom1.save!

      bedroom2 = create :area, villa: villa, category: category1, subtype: "schlafzimmer", beds_count: 2
      bedroom2.tag_with("doppelbett", "bedrooms", 1)
      bedroom2.save!

      villa.reload
      expect(villa.bedrooms_count).to eq(2)
      expect(villa.beds_count).to eq(5)
    end

    it "should be able to get tagged with bathrooms" do
      %w[vollbad duschbad gaestewc].each do |subtype|
        bathroom = create :area, villa: villa, category: category2, subtype: subtype
        bathroom.tag_with("wc", "bathrooms")
        bathroom.save!
      end

      expect(villa.bathrooms_count).to eq(2)
      expect(villa.wcs_count).to eq(3)
    end
  end
end
