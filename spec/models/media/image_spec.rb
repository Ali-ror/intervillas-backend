require "rails_helper"

RSpec.describe Media::Image do
  describe "#cache_key changes with name in locale" do
    let(:image) { create :image, parent: create(:villa), updated_at: 1.hour.ago }

    it { expect { image.en_description = "bar"; image.save! }.to change(image, :cache_key) }
    it { expect { image.de_description = "foo"; image.save! }.to change(image, :cache_key) }
  end
end
