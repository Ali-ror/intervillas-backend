require "rails_helper"

RSpec.describe Description, vcr: { cassette_name: "villa/geocode" } do
  subject { create :description, category: category }

  let(:category) { create :category }

  %w[villa_id key].each do |col|
    it { is_expected.to have_db_column col }
  end

  it { is_expected.to belong_to(:villa) }
  it { is_expected.to validate_uniqueness_of(:key).scoped_to(:villa_id) }

  %w[villa_id key].each do |col|
    it { is_expected.to validate_presence_of col }
  end

  it { is_expected.not_to validate_presence_of :text }
end
