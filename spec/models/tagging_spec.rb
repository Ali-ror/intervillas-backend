require "rails_helper"

RSpec.describe Tagging, vcr: { cassette_name: "villa/geocode" } do
  before { create :tagging }

  describe "#tag" do
    it { is_expected.to have_db_column :tag_id }
    it { is_expected.to belong_to :tag }
    it { is_expected.to validate_presence_of :tag }
  end

  describe "#taggable" do
    it { is_expected.to have_db_column :taggable_type }
    it { is_expected.to have_db_column :taggable_id }
    it { is_expected.to belong_to :taggable }
    it { is_expected.to validate_presence_of :taggable }
    it { is_expected.to validate_uniqueness_of(:tag_id).scoped_to(:taggable_type, :taggable_id) }
  end

  describe "#amount" do
    it { is_expected.to have_db_column :amount }
    it { is_expected.to validate_numericality_of(:amount) }
  end
end
