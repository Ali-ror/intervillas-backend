require "rails_helper"

RSpec.describe Currency::Value do
  context "factories" do
    describe ".euro(numeric)" do
      subject(:value) { Currency::Value.euro(1) }

      it "is in EUR" do
        expect(value.currency).to eq Currency::EUR
      end
    end

    describe ".make_value(numeric, currency)" do
      context "with Numeric" do
        subject(:value) { Currency::Value.make_value(1, Currency::EUR) }

        it "returns Value" do
          expect(value).to be_a Currency::Value
        end
      end

      context "with Value" do
        subject(:value) { Currency::Value.make_value(inner_value, Currency::EUR) }

        let(:inner_value) { Currency::Value.make_value(1, Currency::EUR) }

        it "returns Value" do
          expect(value).to eql inner_value
        end
      end
    end

    describe ".convert" do
      subject(:eur) { Currency::Value.convert(1, Currency::USD, ceil: ceil) }

      let(:ceil) { true }

      context "to USD" do
        it { expect(eur.currency).to eq Currency::USD }
        it { expect(eur.value).to eq 2 }

        context "ceil: false" do
          let(:ceil) { false }

          it { expect(eur.value).to eq 1.32687 } # 1.282 * 1.035
        end
      end
    end

    context "1" do
      subject(:value) { Currency::Value.euro(1) }

      describe "#<=>" do
        let(:bigger) { value + 1 }
        let(:smaller) { value - 1 }

        it { expect(value <=> value).to eq 0 }
        it { expect(value <=> bigger).to eq(-1) }
        it { expect(value <=> 2).to eq(-1) }
        it { expect(value <=> smaller).to eq 1 }
      end

      describe "#*" do
        it { expect(value * 2).to eq 2 }
        it { expect(value * 2).to be_a Currency::Value }
      end

      describe "#/" do
        it { expect(value / 2).to eq 0.5 }
        it { expect(value / 2).to be_a Currency::Value }
      end

      describe "#-@" do
        it { expect(-value).to eq(-1) }
        it { expect(-value).to be_a Currency::Value }
      end

      describe "#round" do
        subject(:value) { Currency::Value.euro(1.004) }

        it { expect(value.round(2)).to eq(1) }
        it { expect(value.round(2)).to be_a Currency::Value }
      end

      describe "#ceil!" do
        subject(:value) { Currency::Value.euro(1.04) }

        it { expect(value.ceil!).to eq(2) }
        it { expect(value.ceil!).to be_a Currency::Value }
      end

      describe "#abs" do
        subject(:value) { Currency::Value.euro(-1) }

        it { expect(value.abs).to eq(1) }
        it { expect(value.abs).to be_a Currency::Value }
      end

      describe "#convert" do
        subject(:value) { Currency::Value.new(1, Currency::USD) }

        context "USD to EUR" do
          it { expect { value.convert(Currency::EUR) }.to raise_exception(RuntimeError) }
        end
      end

      describe ">" do
        # Spezialfall leerer Wert
        subject(:value) { Currency::Value.new("", Currency::USD) }

        it do
          expect(value > 0).to be_falsey
        end

        it { expect(value).to eq 0 }
      end
    end
  end
end
