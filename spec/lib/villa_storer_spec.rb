require "rails_helper"
# require "app/lib/villa_storer"

RSpec.describe VillaStorer, vcr: { cassette_name: "admin_villa/geocode" } do
  subject(:storer) { VillaStorer.new(villa) }

  before { restore_tags! }

  let!(:owner) { create :contact }
  let!(:manager) { create :contact }

  let(:villa) { Villa.new }

  def permitted_params(attrs)
    price_params = [
      :_destroy, :currency,
      :base_rate, :additional_adult, :children_under_6, :children_under_12,
      :cleaning, :deposit,
      { id: [] },
    ]

    ActionController::Parameters.new(attrs).permit %i[
      active buyable name safe_code phone manager_id owner_id street
      postal_code locality region country living_area pool_orientation
    ] + [{
      calendars:         %i[id _destroy url name],
      domain_ids:        [],
      taggings:          %i[tag_id amount],
      descriptions:      %i[id key category_id de en],
      areas:             [:id, :_destroy, :category_id, :subtype, :beds_count, { taggings: %i[tag_id amount] }],
      villa_price_eur:   price_params,
      villa_price_usd:   price_params,
      holiday_discounts: %i[id _destroy description percent days_before days_after],
      boat:              [:inclusion, :exclusive_id, { optional_ids: [] }],
    }]
  end

  context "without basic attributes" do
    it "fails to store villa w/o AC::Params" do
      expect {
        storer.store!({})
      }.to raise_error ActiveRecord::RecordInvalid
    end

    it "fails to store villa w/ AC::Params" do
      expect {
        storer.store! permitted_params({})
      }.to raise_error ActiveRecord::RecordInvalid
    end
  end

  context "given basic attributes" do
    let(:basic_attributes) {
      {
        active:      true,
        buyable:     false,
        name:        "Test Villa",
        living_area: 1000,
        safe_code:   "",
        phone:       "(555) 123-456",
        owner_id:    owner.id,
        manager_id:  manager.id,
        street:      "5608 SW 9th Ave",
        locality:    "Cape Coral",
        region:      "FL",
        postal_code: "33914",
        country:     "US",
      }
    }

    # extend attributes in sub-context
    let(:attributes) { basic_attributes }

    before { storer.store! permitted_params(attributes) }

    it { expect(villa).to be_persisted }

    context "adding tags" do
      def randomize(collection)
        collection.order Arel.sql("random()")
      end

      let(:tags) {
        cat   = Category.select(:id)
        # villa has all the highlights
        tags  = Tag.where(category_id: cat.where(name: "highlights")).to_a
        # and some other random tags (excluding those belonging to areas)
        tags += randomize(Tag.where.not(category_id: cat.where.not(multiple_types: nil))).limit(15).to_a
        tags.uniq
      }

      let(:taggings) {
        # if a tag is countable, use the tag id as amount
        tags.map { |t|
          { tag_id: t.id, amount: t.countable? ? t.id : 1 }
        }
      }

      let(:attributes) { basic_attributes.merge(taggings:) }

      it "saves them" do
        tags.each do |t|
          if t.countable?
            expect(villa).to be_tagged_with(t, amount: t.id)
          else
            expect(villa).to be_tagged_with(t)
          end
        end

        # check that no other tagging exists
        tag = randomize(Tag.where.not(id: tags.map(&:id))).first
        expect(villa).not_to be_tagged_with(tag)
      end
    end

    context "adding descriptions" do
      let(:category) { Category.find_by(name: "highlights") }
      let(:known_descriptions_keys) { { header: 5, teaser: 30, description: 100 } }

      let(:descriptions) {
        known_descriptions_keys.map { |key, length|
          {
            category_id: category.id,
            key:,
            de:          Faker::Lorem.sentence(word_count: length),
            en:          Faker::Lorem.sentence(word_count: length),
          }
        }
      }

      let(:attributes) { basic_attributes.merge(descriptions:) }

      it "saves them" do
        descriptions.each do |d|
          desc = villa.descriptions.includes(:translations).find_by(key: d[:key])
          desc.translations.each do |tr|
            expect(tr.text).to eq d[tr.locale]
          end
        end
      end
    end

    context "adding areas" do
      let(:bedroom_cat) { Category.find_by(name: "bedrooms") }

      let(:bedrooms) {
        rooms = 3.times.map { bedroom_cat.multiple_types.sample }
        rooms.map.with_index { |subtype, i|
          taggings = (i + 1).times.map { bedroom_cat.tags.sample }.map { |t|
            { tag_id: t.id, amount: 1 }
          }

          {
            category_id: bedroom_cat.id,
            subtype:,
            taggings:,
            beds_count:  i + 1,
          }
        }
      }

      let(:attributes) { basic_attributes.merge(areas: bedrooms) }

      it "saves them" do
        expect(villa.bedrooms_count).to be bedrooms.size
        expect(villa.beds_count).to be bedrooms.pluck(:beds_count).sum
        expect(villa.bathrooms_count).to be 0
      end
    end

    context "assigning boats" do
      let(:boats) { create_list :boat, 3 }

      let(:boat_attributes) {
        {
          inclusion:    "optional",
          optional_ids: [boats[0].id, boats[1].id],
          exclusive_id: boats[2].id,
        }
      }

      let(:attributes) { basic_attributes.merge(boat: boat_attributes) }

      it "saves the association" do
        expect(villa.optional_boat_ids).to contain_exactly(boats[1].id, boats[0].id)
      end

      it "honors the inclusion type" do
        # optional boats == no exclusive boat
        expect(villa.inclusive_boat).to be_nil
        expect(boats[2].reload.villa_id).to be_nil
      end
    end

    context "switching to USD prices" do
      let(:eur) {
        {
          base_rate:         356,
          additional_adult:  10,
          children_under_6:  0,
          children_under_12: 0,
          cleaning:          250,
          deposit:           1000,
        }
      }

      let(:usd) {
        {
          base_rate:         420,
          additional_adult:  15,
          children_under_6:  0,
          children_under_12: 0,
          cleaning:          285,
          deposit:           1200,
        }
      }

      let(:attributes) {
        basic_attributes.merge(villa_price_eur: eur)
      }

      it {
        expect(villa.villa_price_eur).to be_persisted

        expect {
          storer.store! permitted_params(
            villa_price_eur: { id: villa.villa_price_eur.id, _destroy: true },
            villa_price_usd: usd,
          )
        }.to change(VillaPrice.where(villa_id: villa.id, currency: "EUR"), :count).by(-1)
          .and change(VillaPrice.where(villa_id: villa.id, currency: "USD"), :count).by(1)
      }
    end

    context "adding prices" do
      let(:discounts) {
        [
          { description: "christmas", percent: 20, days_before: 1, days_after: 14 },
          { description: "easter", percent: 20, days_before: 3, days_after: 7 },
        ]
      }

      let(:villa_price) {
        {
          base_rate:         356,
          additional_adult:  10,
          children_under_6:  0,
          children_under_12: 0,
          cleaning:          250,
          deposit:           1000,
        }
      }

      let(:attributes) {
        basic_attributes.merge \
          villa_price_eur:   villa_price,
          holiday_discounts: discounts
      }

      it "saves them" do
        expect(villa.villa_price_eur).to be_persisted

        discounts.each do |hd|
          expect(
            HolidayDiscount.where(villa_id: villa.id).where(hd),
          ).to be_exist
        end
      end

      it "does not touch existing prices when nothing changes" do
        expect {
          storer.store! permitted_params(villa_price_eur: villa_price)
        }.not_to change(villa.villa_price, :updated_at)
      end
    end
  end
end
