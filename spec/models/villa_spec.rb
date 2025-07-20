require "rails_helper"

RSpec.describe Villa, vcr: { cassette_name: "villa/geocode" } do
  subject { create :villa }

  let(:category) { create :category, :highlights }

  %i[name active buyable living_area street locality region postal_code country].each do |column|
    it { is_expected.to have_db_column column }
  end

  %i[name living_area].each do |column|
    it { is_expected.to validate_presence_of column }
  end

  it { is_expected.to validate_uniqueness_of :name }

  %i[active buyable].each do |column|
    [true, false].each do |bool|
      it { is_expected.to allow_value(bool).for(column) }
    end

    it { is_expected.not_to allow_value(nil).for(column) }
  end

  %i[
    areas
    blockings
    bookings
    calendars
    descriptions
    holiday_discounts
    images
    inquiries
    pannellums
    taggings
    tags
    tours
  ].each do |col|
    it { is_expected.to have_many(col) }
  end

  it { is_expected.to have_and_belong_to_many :specials }
  it { is_expected.to have_and_belong_to_many :high_seasons }

  it { is_expected.to belong_to(:owner).optional }
  it { is_expected.to belong_to(:manager).optional }

  describe "#minimum_people" do
    subject(:villa) { create :villa }

    it "can be changed, when child prices are absent" do
      villa.minimum_people = 4
      expect(villa).to be_valid
    end

    it "can't be changed, when child prices are present" do
      create :villa_price, villa: villa
      villa.minimum_people = 4
      expect(villa).not_to be_valid
      expect(villa.errors.details).to match(minimum_people: [{ error: :has_child_prices }])
    end
  end

  describe "a villa" do
    subject(:villa) { create :villa }

    it "is able to get tagged" do
      villa.tag_with("fireplace", "living_room")
      villa.save!
      tag = Tag.where(name: "fireplace").first
      expect(villa).to be_tagged_with(tag)
    end

    it "is able to get tagged countable" do
      villa.tag_with("seats", "living_room", 7)
      villa.save!
      tag = Tag.where(name: "seats", category_id: Category.where(name: "living_room")).first
      expect(villa).to be_tagged_with(tag, amount: 7)
      expect(Category.tags_for("living_room")).to include("seats")
    end

    it "has description texts" do
      key   = generate(:description_key)
      desc  = create(:description, key: key, category: category, villa: villa)
      expect(villa.descriptions.get(key).text).to eql(desc.text)
    end

    it "sets description texts" do
      expect(category).to be_persisted
      villa.descriptions.reload.set(:header, I18n.locale, "test header")
      villa.save!
      expect(villa.descriptions.get(:header).to_s).to eq "test header"
    end

    it "builds associtated bedroom" do
      create(:category, name: "bedrooms")
      bedroom = villa.bedrooms.build
      bedroom.save!
      expect(villa.bedrooms).to include(bedroom)
    end

    it "builds associtated bathrooms" do
      create(:category, name: "bathrooms")
      bathroom = villa.bathrooms.build
      bathroom.save!
      expect(villa.bathrooms).to include(bathroom)
    end
  end

  describe "a new villa" do
    let(:villa) { build(:villa) }

    it "accepts values for description" do
      expect(category).to be_persisted
      expect(villa).to be_new_record
      villa.descriptions.set(:header, "de", "test header")
      villa.save!

      I18n.with_locale("de") do
        expect(villa.descriptions.get(:header).to_s).to eq "test header"
      end
    end
  end

  describe "a villa with descriptions" do
    let(:villa) { create(:villa, :bookable, :with_descriptions) }

    before do
      villa.descriptions.set(:header, I18n.locale, "test header")
      villa.save!
    end

    it "gets destroyed" do
      villa.destroy
      expect { villa.reload }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  describe "a villa with special" do
    let(:villa)   { create(:villa, :bookable) }
    let(:special) { create(:special) }

    before do
      special.villas << villa
    end

    it "has special teaser price" do
      expect(villa).to respond_to(:teaser_special_price)
    end

    it "calculates special teaser price" do
      # 160 * 7 * 0.9 (10 % off)
      expect(villa.teaser_special_price(special).to_d).to eq(BigDecimal(1008))
    end
  end

  describe "#cache_key" do
    subject(:villa) { create :villa, :with_descriptions, updated_at: 1.hour.ago }

    before do
      villa.updated_at = 1.hour.ago
      villa.save
    end

    it "changes with name" do
      expect {
        villa.name = "foo"
        villa.save!
      }.to change(villa, :cache_key)
    end

    it "changes with highlights_boot" do
      expect {
        villa.tag_with("boot", "highlights", 1)
        villa.reload
      }.to change(villa, :cache_key)
    end

    %w[de en].each do |locale|
      it "changes with teaser (:descriptions)" do
        expect {
          villa.descriptions.set(:teaser, locale, "foo")
          villa.reload
        }.to change(villa, :cache_key)
      end
    end
  end

  describe ".search" do
    subject(:search) { Villa.search(Date.current, 2.weeks.from_now) }

    let!(:villas) { create_list :villa, 3, :bookable }
    let!(:booking) { create_full_booking villa: villas[0], start_date: 1.week.from_now }
    let!(:blocking) { create :blocking, villa: villas[1], start_date: 1.week.from_now }

    it { expect(search).to include villas[2] }
    it { expect(search).not_to include villas[0] }
    it { expect(search).not_to include villas[1] }
  end

  describe "domain contraint" do
    let(:villas) { create_list :villa, 2, no_domain: true }

    let(:canonical_domain) { "intervillas-florida.com" }
    let(:secondary_domain) { "cape-coral-ferienhaeuser.com" }

    before do
      villas[0].domains << create(:domain, name: canonical_domain)
      villas[1].domains << create(:domain, name: secondary_domain)
    end

    context "on canonical domain" do
      subject { Villa.on_domain(canonical_domain) }

      it { is_expected.to     include villas[0] }
      it { is_expected.not_to include villas[1] }
    end

    context "on secondary domain" do
      subject { Villa.on_domain(secondary_domain) }

      it { is_expected.not_to include villas[0] }
      it { is_expected.to     include villas[1] }
    end
  end
end
