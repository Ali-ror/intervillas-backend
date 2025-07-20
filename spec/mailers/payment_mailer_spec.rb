require "rails_helper"

RSpec.describe PaymentMailer do
  include ActionView::Helpers::NumberHelper

  let(:inquiry) {
    create_full_booking_with_boat(
      boat_state:        :optional,
      with_owner:        true,
      with_manager:      true,
      with_boat_manager: true,
      start_date:        90.days.from_now,
      end_date:          110.days.from_now,
    ).inquiry
  }
  let(:customer)          { inquiry.customer }
  let(:rentables)         { booking.rentable_names.join(" / ") }
  let(:booking)           { inquiry.booking }
  let(:payment_deadlines) { booking.payment_deadlines }

  describe "#payment_mail_reloaded" do
    let(:message) {
      build :message,
        inquiry:  inquiry,
        template: :payment_mail_reloaded,
        text:     "foo text"
    }
    let(:mail) {
      PaymentMailer.payment_mail_reloaded \
        inquiry: inquiry,
        message: message,
        to:      customer.email
    }

    it "renders the localized subject" do
      expect(mail.subject).to eq "#{inquiry.number}: Bestätigung Zahlungseingang - Intervilla"
    end

    shared_examples "a Payment mail" do |locale|
      include PaymentMailer::PaymentDeadlinesView

      before { I18n.locale = locale if locale } # rubocop:disable Rails/I18nLocaleAssignment

      it "renders the headers" do
        expect(mail.from).to include "info@intervillas-florida.com"
        expect(mail.to).to include inquiry.customer.email
      end

      it "includes inquiry information" do
        [
          ERB::Util.html_escape(customer.salutation),
          number_to_currency(payment_deadlines.paid_total),
          booking.number,
          rentables,
          message.text,
          number_to_currency(payment_deadlines.total, unit: ""),
          number_to_currency(payment_deadlines.difference, unit: ""),
        ].each do |information|
          expect(mail.body.encoded).to include information
        end
      end

      it "includes deadline information" do
        deadlines.each do |deadline|
          [
            deadline.name,
            deadline.date,
            number_to_currency(deadline.sum, unit: ""),
          ].each do |information|
            expect(mail.body.encoded).to include information
          end
        end
      end

      it "includes payment information" do
        payments.each do |payment|
          [
            payment.date,
            number_to_currency(payment.sum, unit: ""),
          ].each do |information|
            expect(mail.body.encoded).to include information
          end
        end
      end
    end

    it_behaves_like "a Payment mail"

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
        expect(mail.subject).to eq "#{inquiry.number}: Payment Confirmation - Intervilla"
      end

      it_behaves_like "a Payment mail", :en
    end
  end

  describe "#payment_reminder" do
    let(:mail) {
      PaymentMailer.payment_reminder \
        inquiry: inquiry,
        to:      customer.email
    }

    it "renders the localized subject" do
      expect(mail.subject).to eq "#{inquiry.number}: Zahlungshinweis - Intervilla"
    end

    shared_examples "a Payment reminder" do |locale|
      before { I18n.locale = locale if locale } # rubocop:disable Rails/I18nLocaleAssignment

      it "renders the headers" do
        expect(mail.from).to include "info@intervillas-florida.com"
        expect(mail.to).to include inquiry.customer.email
      end

      it "includes payment information" do
        [
          ERB::Util.html_escape(customer.salutation),
          rentables,
          booking.number,
          number_to_currency(payment_deadlines.due_balances),
        ].each do |information|
          expect(mail.body.encoded).to include information
        end
      end
    end

    it_behaves_like "a Payment reminder"

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
        expect(mail.subject).to eq "#{inquiry.number}: Payment Reminder - Intervilla"
      end

      it_behaves_like "a Payment reminder", :en
    end
  end
end
