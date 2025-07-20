require "rails_helper"

RSpec.describe Billing::Template::Tenant do
  subject(:template) { Billing::Template::Tenant.new tenant_billing }

  let(:booking) { create_full_booking }
  let(:tenant_billing) { booking.to_billing.tenant_billing }

  describe ":payment_method" do
    context "without payment" do
      it { expect(template.payment_method).to eq :transfer }
    end

    context "with payment via bsp1" do
      before do
        create :payment, scope: :bsp1, booking: booking
      end

      it { expect(template.payment_method).to eq :credit_card }
    end

    context "with payment via paypal" do
      before do
        create :payment, scope: :paypal, booking: booking
      end

      it { expect(template.payment_method).to eq :credit_card }
    end

    context "with payment via transfer" do
      before do
        create :payment, scope: :transfer, booking: booking
      end

      it { expect(template.payment_method).to eq :transfer }
    end
  end
end
