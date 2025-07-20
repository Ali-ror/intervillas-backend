require "rails_helper"

RSpec.describe Api::Bsp1::PseudocardpansController do
  describe "#create" do
    let(:inquiry) { create :inquiry }
    let!(:booking) { create :booking, inquiry: inquiry }

    before do
      post :create, params: { pseudocardpan: "123456", inquiry_token: inquiry.token }
    end

    it { is_expected.to respond_with :success }
  end
end
