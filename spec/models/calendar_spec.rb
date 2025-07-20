require "rails_helper"
require "validate_url/rspec_matcher"

RSpec.describe Calendar do
  it { is_expected.to belong_to :villa }
  it { is_expected.to have_many :blockings }

  it { is_expected.to validate_presence_of :url }
  it { is_expected.to validate_url_of(:url) }

  context "with a Calendar" do
    before do
      create :calendar
    end

    it { is_expected.to validate_uniqueness_of :url }
  end
end
