require "rails_helper"

RSpec.describe Category do
  subject { create :category }

  before do
    @valid_attributes = {
      name:           "value for name",
      multiple_types: "value for multiple_types",
    }
  end

  it "should create a new instance given valid attributes" do
    Category.create!(@valid_attributes)
  end

  %w[name multiple_types].each do |col|
    it { is_expected.to have_db_column col }
  end

  it { is_expected.to validate_presence_of :name }
  it { is_expected.to validate_uniqueness_of :name }

  %i[tags areas].each do |col|
    it { is_expected.to have_many(col) }
  end

  describe "#multiple_types is serialized" do
    before do
      subject.update_attribute :multiple_types, %w[a b c]
      subject.reload
    end

    its(:multiple_types) { is_expected.to eq %w[a b c] }
  end
end
