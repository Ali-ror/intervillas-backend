require "rails_helper"

RSpec.describe BillingMailer do
  let(:booking) { create_full_booking with_owner: true }
  let(:inquiry) { booking.inquiry }
  let(:villa) { inquiry.villa }
  let(:owner) { villa.owner }
  let!(:villa_billing) { create :villa_billing, villa_inquiry: booking.villa_inquiry }

  def quoted_printable(string)
    [ERB::Util.html_escape(string)].pack("M").strip[0...-1] # quoted printable -> letztes '=' abschneiden
  end

  describe "#villa_owner_billing" do
    let(:mail) {
      BillingMailer.villa_owner_billing(
        inquiry: inquiry,
        message: message,
        to:      owner.email_addresses.first,
      )
    }
    let(:message) {
      build :message,
        inquiry:   inquiry,
        template:  :villa_owner_billing,
        recipient: owner
    }

    it "renders the subject" do
      expect(mail.subject).to eq "#{inquiry.number}: Abrechnung/Statement - Intervilla"
    end

    it "renders the headers" do
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include owner.email_addresses.first
    end

    it "includes billing information" do
      I18n.with_locale :en do
        [
          quoted_printable(owner.salutation),
          villa.name,
          booking.number,
          message.text,
        ].each do |information|
          expect(mail.body.encoded).to include information
        end
      end
    end

    it "attaches pdf" do
      expect(mail.attachments).to include an_object_having_attributes(
        filename:  "billing.pdf",
        mime_type: "application/pdf",
      )
    end
  end

  describe "#tenant_billing" do
    let(:customer) { inquiry.customer }
    let(:message) {
      build :message,
        inquiry:  inquiry,
        template: :tenant_billing,
        text:     "foo text"
    }
    let(:mail) {
      BillingMailer.tenant_billing(
        inquiry: inquiry,
        message: message,
        to:      customer.email,
      )
    }

    it "renders the localized subject" do
      expect(mail.subject).to eq "#{inquiry.number}: Nebenkosten/Kautionsabrechnung - Intervilla"
    end

    shared_examples "a Tenant billing" do |locale|
      it "renders the headers" do
        expect(mail.from).to include "info@intervillas-florida.com"
        expect(mail.to).to include customer.email
      end

      around { |ex| I18n.with_locale(locale, &ex) }

      it "includes billing information" do
        [
          quoted_printable(customer.salutation),
          booking.number,
          villa.name,
          message.text,
        ].each do |information|
          expect(mail.body.encoded).to include information
        end
      end

      it "attaches pdf" do
        expect(mail.attachments).to include an_object_having_attributes(
          filename:  "billing.pdf",
          mime_type: "application/pdf",
        )
      end
    end

    it_behaves_like "a Tenant billing", :de

    context "with locale :en" do
      alias_method :de_mail, :mail
      let!(:mail) {
        I18n.with_locale(:de) { inquiry }
        I18n.with_locale :en do
          de_mail.subject
          de_mail
        end
      }

      it "renders the localized subject" do
        expect(mail.subject).to eq "#{inquiry.number}: Statement/Deposit/Charges - Intervilla"
      end

      it_behaves_like "a Tenant billing", :en
    end
  end
end
