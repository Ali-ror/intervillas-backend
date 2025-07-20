require "rails_helper"

RSpec.describe Tag do
  %w[category_id name countable].each do |col|
    it { is_expected.to have_db_column col }
  end

  %w[category name].each do |col|
    it { is_expected.to validate_presence_of col }
  end

  it { is_expected.to belong_to(:category) }

  %w[areas villas taggings].each do |col|
    it { is_expected.to have_many(col.to_sym) }
  end

  context "with a tag" do
    before { create :tag }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:category_id) }
  end

  [true, false].each do |value|
    it { is_expected.to allow_value(value).for(:countable) }
  end

  it { is_expected.not_to allow_value(nil).for(:countable) }
end
