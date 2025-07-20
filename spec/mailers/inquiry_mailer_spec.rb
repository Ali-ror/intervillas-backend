require "rails_helper"

RSpec.describe InquiryMailer do
  let(:inquiry) { create :inquiry, :with_villa_inquiry }
  let(:customer) { inquiry.customer }

  shared_examples "a Submission mail" do |locale = :de|
    it "renders the headers" do
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include inquiry.customer.email
    end

    it "includes customer salutation" do
      expect(mail.body.encoded).to include ERB::Util.html_escape(customer.salutation)
    end

    it "includes booking_url" do
      opts             = { token: inquiry.token }
      opts[:subdomain] = locale == :en ? "en.self" : "www.self"
      expect(mail.body.encoded).to include new_booking_url(opts)
    end
  end

  describe "#submission_mail" do
    let(:mail) { InquiryMailer.submission_mail(inquiry: inquiry, to: inquiry.customer.email) }

    it "renders the localized subject" do
      expect(mail.subject).to eq "Ihre Anfrage #{inquiry.number} #{inquiry.villa_inquiry.villa_name}"
    end

    it_behaves_like "a Submission mail"

    context "with locale :en" do
      let(:mail) do
        I18n.with_locale :en do
          inquiry
          mail = InquiryMailer.submission_mail(inquiry: inquiry, to: inquiry.customer.email)
          mail.subject
          mail
        end
      end

      it "renders the localized subject" do
        expect(mail.subject).to eq "Your Booking Request #{inquiry.number} #{inquiry.villa_inquiry.villa_name}"
      end

      it_behaves_like "a Submission mail", :en
    end

    context "external booking" do
      let(:inquiry) { create :inquiry, :external }

      it "raises error" do
        expect {
          mail.subject
        }.to raise_error Bookings::External::Error
      end
    end
  end

  describe "#reminder_mail" do
    let(:mail) { InquiryMailer.reminder_mail(inquiry: inquiry, to: inquiry.customer.email) }

    it "renders the localized subject" do
      expect(mail.subject).to eq "(Erinnerung) Ihre Anfrage #{inquiry.number} #{inquiry.villa_inquiry.villa_name}"
    end

    shared_examples "a Reminder mail" do
      it "renders the headers" do
        expect(mail.from).to include "info@intervillas-florida.com"
        expect(mail.to).to include inquiry.customer.email
      end

      it "includes inquiry information" do
        [
          ERB::Util.html_escape(customer.salutation),
        ].each do |information|
          expect(mail.body.encoded).to include information
        end
      end
    end

    it_behaves_like "a Reminder mail"

    it "includes link to book" do
      mail_body = Capybara.string(mail.body.encoded)
      expect(mail_body).to have_link "Buchung abschliessen", href: new_booking_url(token: inquiry.token, subdomain: "www.self")
    end

    context "with locale :en" do
      let(:mail) do
        I18n.with_locale :en do
          inquiry
          mail = InquiryMailer.reminder_mail(inquiry: inquiry, to: inquiry.customer.email)
          mail.subject
          mail
        end
      end

      it "renders the localized subject" do
        expect(mail.subject).to eq "Your Booking Request-Reminder #{inquiry.number} #{inquiry.villa_inquiry.villa_name}"
      end

      it_behaves_like "a Reminder mail"

      it "includes link to book" do
        mail_body = Capybara.string(mail.body.encoded)
        expect(mail_body).to have_link "Book now", href: new_booking_url(token: inquiry.token, subdomain: "en.self")
      end
    end
  end
end
