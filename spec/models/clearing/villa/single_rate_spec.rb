require "rails_helper"

class Clearing
  class Villa < Rentable
    RSpec.describe SingleRate do
      subject(:single_rate) { SingleRate.new(BigDecimal(70), normal_price: BigDecimal(70)) }
      let(:equal) { SingleRate.new(BigDecimal(70), normal_price: BigDecimal(70)) }
      let(:different) { SingleRate.new(BigDecimal(70), normal_price: BigDecimal(60)) }

      describe "#==(other)" do
        it { expect(single_rate).to eq equal }
        it { expect(single_rate).not_to eq different }
      end

      describe "use as hash key" do
        let(:hash) { {} }

        before do
          hash[single_rate] = :foo
          hash[different]   = :bar
        end

        it { expect(hash[single_rate]).to eq :foo }
        it { expect(hash[equal]).to eq :foo }
        it { expect(hash[different]).to eq :bar }

        context "overwrite with other but equal key" do
          before do
            hash[equal] = :baz
          end

          it { expect(hash[single_rate]).to eq :baz }
          it { expect(hash[equal]).to eq :baz }
          it { expect(hash[different]).to eq :bar }
        end
      end
    end
  end
end
