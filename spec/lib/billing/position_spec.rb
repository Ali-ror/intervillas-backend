require "rails_helper"

RSpec.describe Billing::Position do
  let(:eps) { 1e-16 }

  context "single tax value" do
    subject { Billing::Position.new "subject", "context", gross, tax }

    let(:gross) { 212 }
    let(:net)   { 200 }
    let(:tax)   { :sales } # 6%

    its(:subject) { is_expected.to eq "subject" }
    its(:context) { is_expected.to eq "context" }
    its(:gross)   { is_expected.to be_within(eps).of(gross) }
    its(:net)     { is_expected.to be_within(eps).of(net) }
    its(:tax)     { is_expected.to be_within(eps).of(12) }

    it { expect(subject.proportions.keys).to eq [:sales] }
    it { is_expected.to be_valid }

    context "in 2019" do
      let(:gross) { 213 }
      let(:tax)   { :sales_2019 } # tax = 6.5%

      its(:gross) { is_expected.to be_within(eps).of(gross) }
      its(:net)   { is_expected.to be_within(eps).of(net) }
      its(:tax)   { is_expected.to be_within(eps).of(13) }
    end
  end

  context "multiple tax values" do
    subject { Billing::Position.new "subject", "context", gross, *tax }

    let(:gross) { 333 }
    let(:net)   { 300 }
    let(:tax)   { %i[sales tourist] } # 6% + 5% = 11%

    its(:subject) { is_expected.to eq "subject" }
    its(:context) { is_expected.to eq "context" }
    its(:gross)   { is_expected.to be_within(eps).of(gross) }
    its(:net)     { is_expected.to be_within(eps).of(net) }
    its(:tax)     { is_expected.to be_within(eps).of(33) }

    it { expect(subject.proportions.keys).to eq %i[sales tourist] }
    it { is_expected.to be_valid }

    context "in 2019" do
      let(:gross) { 334.5 }
      let(:tax)   { %i[sales_2019 tourist] } # 6.5% + 5% = 11.5%

      its(:gross) { is_expected.to be_within(eps).of(gross) }
      its(:net)   { is_expected.to be_within(eps).of(net) }
      its(:tax)   { is_expected.to be_within(eps).of(34.5) }
    end
  end

  context "with Currency::Value" do
    it "keeps type" do
      position = Billing::Position.new(:deposit, :context, Currency::Value.new(1, Currency::USD))
      expect(position.gross).to be_a Currency::Value
    end
  end
end
