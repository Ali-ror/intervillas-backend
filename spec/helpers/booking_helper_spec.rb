require "rails_helper"

# Specs in this file have access to a helper object that includes
# the BookingHelperHelper. For example:
#
# describe BookingHelperHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe BookingHelper do
  describe "#reservation_conflict?(inquiry)" do
    let!(:inquiry) { create_villa_inquiry.inquiry }

    context "no conflict" do
      it { expect(helper.reservation_conflict?(inquiry)).to eq false }
    end

    context "with conflicting reservation" do
      before do
        create_reservation(villa: inquiry.villa, start_date: inquiry.start_date)
      end

      it { expect(helper.reservation_conflict?(inquiry)).to eq true }
    end
  end
end
