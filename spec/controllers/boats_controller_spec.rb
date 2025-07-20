require "rails_helper"

RSpec.describe BoatsController do
  render_views

  describe "#show" do
    let(:boat) { create :boat, :active }

    before do
      get :show, params: { id: boat.id }
    end

    it { is_expected.to respond_with :success }
  end
end
