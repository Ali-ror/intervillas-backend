require "rails_helper"

RSpec.describe Taxable do
  let(:eps) { 1e-10 } # epsilon (desired floating point precision)

  def rat(numerator, denominator)
    Rational(numerator, denominator).to_f
  end

  describe "#to_net" do
    it { expect(Taxable.to_net(100, 0.2)).to be_within(eps).of rat(100, 1.2) }
    it { expect(Taxable.to_net(100, 20)).to be_within(eps).of rat(100, 1.2) }

    it { expect(Taxable.to_net(100, 0.01)).to be_within(eps).of rat(100, 1.01) }
    it { expect(Taxable.to_net(100, 99)).to be_within(eps).of rat(100, 1.99) }

    context "random example" do
      let(:rand_tax)      { rand }
      let(:rand_gross)    { rand 10..1000 }
      let(:rand_expected) { rat(rand_gross, 1 + rand_tax) }
      let(:rand_actual)   { Taxable.to_net(rand_gross, rand_tax) }

      it { expect(rand_actual).to be_within(eps).of rand_expected }
    end
  end

  describe "#to_gross" do
    it { expect(Taxable.to_gross(100, 0.2)).to be_within(eps).of 120 }
    it { expect(Taxable.to_gross(100, 20)).to be_within(eps).of 120 }

    it { expect(Taxable.to_gross(100, 0.01)).to be_within(eps).of 101 }
    it { expect(Taxable.to_gross(100, 99)).to be_within(eps).of 199 }

    context "random example" do
      let(:rand_tax) { rand }
      let(:rand_net) { rand 10..1000 }
      let(:rand_expected) { rat(rand_net, rat(1, 1 + rand_tax)) }
      let(:rand_actual)   { Taxable.to_gross(rand_net, rand_tax) }

      it { expect(rand_actual).to be_within(eps).of rand_expected }
    end
  end

  describe "#tax" do
    let(:tax_val) { 0.136 }
    let(:net)     { 100 }
    let(:gross)   { Taxable.to_gross net, tax_val }
    let(:tax)     { Taxable.tax      net, tax_val }

    it { expect(net + tax).to be_within(eps).of gross }
    it { expect(Taxable.tax(100, 0.13)).to be_within(eps).of 13 }
  end

  # XXX (dm 2015/09/29): Hier werden tatsächlich (und absichtlich) die Werte der
  # Konstanten getestet.
  #
  # Sollte sich an den Steuerwerten mal was ändern, muss die Anwendung auf diese
  # Anpassung vorbereitet werden: Neue Steuersätze sind nämlich erst ab einem
  # bestimmten Datum gültig und bereits abgerechnete Dinge müssen die alten
  # Sätze beachten.
  #
  # Das ist bisher so nicht vorgesehen - und wenn jemand die Steuersätze anpasst
  # werden die nachfolgenden Tests fehlschlagen. Hoffentlich sieht derjenige
  # dann diesen Kommentar...
  describe "#to_tax_factor" do
    subject { ->(x) { Taxable.to_tax_factor(x) } }

    context "tax identified by symbol" do
      it { expect(subject[:sales]).to be_within(eps).of 1.06 }
      it { expect(subject[:sales_2019]).to be_within(eps).of 1.065 }
      it { expect(subject[:tourist]).to be_within(eps).of 1.05 }
      it { expect(subject[:cleaning]).to be_within(eps).of 1.11 }
      it { expect(subject[:energy]).to be_within(eps).of 1.11 }

      context "unknown id" do
        it { expect { subject[:foo] }.to raise_error Taxable::UnknownTaxId }
      end
    end

    context "tax identified by string" do
      it { expect(subject["sales"]).to be_within(eps).of 1.06 }
      it { expect(subject["sales_2019"]).to be_within(eps).of 1.065 }
      it { expect(subject["tourist"]).to be_within(eps).of 1.05 }
      it { expect(subject["cleaning"]).to be_within(eps).of 1.11 }
      it { expect(subject["energy"]).to be_within(eps).of 1.11 }

      context "unknown id" do
        it { expect { subject["bar"] }.to raise_error Taxable::UnknownTaxId }
      end
    end

    context "tax identified value" do
      it { expect(subject[0.4]).to be_within(eps).of 1.4 }
      it { expect(subject[40]).to be_within(eps).of 1.4 }

      it { # Werte zwischen 1.0 und 2.0 sind besonders...
        expect(subject[1.4]).to be_within(eps).of 1.4

        # TODO: MRI 2.7 introduced a LOT of deprecations, which are
        #       silenced for the moment.
        #       With MRI 2.7.2 the situation should improve, but for now
        #       we cut back on this spec.
        # expect {
        #   expect(subject[1.4]).to be_within(eps).of 1.4
        # }.to output(/assuming tax factor already calculated/).to_stderr
      }
    end
  end

  describe "#find_taxes" do
    subject { ->(*k) { Taxable.find_taxes(*k) } }

    it { expect(subject.call).to be_empty }
    it { expect(subject[:sales, :tourist]).to eq(sales: 0.06, tourist: 0.05) }
    it { expect(subject["tourist", "sales"]).to eq(sales: 0.06, tourist: 0.05) }
    it { expect(subject[:energy]).to eq(energy: 0.11) }
    it { expect(subject[:energy, :sales_2019]).to eq(energy: 0.11, sales_2019: 0.065) }
    it { expect { subject[:yadayada] }.to raise_error Taxable::UnknownTaxId }
  end
end
