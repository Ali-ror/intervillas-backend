require "rails_helper"

RSpec.describe Special do
  %w[description start_date end_date percent].each do |col|
    it { is_expected.to have_db_column col }
    it { is_expected.to validate_presence_of col }
  end

  %w[percent].each do |col|
    it { is_expected.to validate_numericality_of col }
  end

  it { is_expected.to have_and_belong_to_many :villas }

  context "a special" do
    let!(:booking) { create_full_booking }
    let(:villa) { booking.villa }
    let!(:special) { create :special, villas: [villa] }

    it { expect(special.villas.available).to include villa }
  end
end
