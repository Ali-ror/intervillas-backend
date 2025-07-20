require "rails_helper"

RSpec.describe BookingMailer do
  include ActionView::Helpers::NumberHelper

  let(:inquiry) do
    create_full_booking_with_boat(
      start_date:        Date.current,
      boat_state:        :optional,
      with_owner:        true,
      with_manager:      true,
      with_boat_manager: true,
    ).inquiry
  end
  let(:customer) { inquiry.customer }
  let(:villa) { inquiry.villa }

  def h(str)
    ERB::Util.html_escape str
  end

  shared_examples "a Confirmation Mail" do |locale|
    it "renders the headers" do
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include customer.email
      expect(mail.bcc).to include "info+kopie@intervillas-florida.com"
    end

    it "includes booking information" do # rubocop:disable RSpec/ExampleLength
      I18n.with_locale locale do
        [
          h(booking.name),
          customer.title,
          h(customer.name),
          h(customer.address),
          customer.appnr,
          customer.postal_code,
          customer.city,
          h(customer.country),
          customer.phone,
          customer.email,
          villa.name,
          villa.locality,
          villa.region,
          villa.country,
          villa.phone,
          villa_inquiry.start_date.to_s,
          villa_inquiry.end_date.to_s,
          villa_inquiry.nights.to_s,
          villa_inquiry.persons.to_s,
          number_to_currency(villa_clearing.total_rents),
          boat.model,
          boat_inquiry.start_date.to_s,
          boat_inquiry.end_date.to_s,
          number_to_currency(clearing.total),
          number_to_currency(clearing.sub_total),
          number_to_currency(clearing.total_deposit),
          number_to_currency(boat_clearing.total_rents),
        ].each do |information|
          expect(mail.body.encoded).to include information
        end

        # Sämtliche Posten sollten erwähnt werden
        [villa_clearing, boat_clearing].flat_map(&:clearing_items).each do |clearing_item|
          next if clearing_item.total.zero?

          expect(mail.body.encoded).to include clearing_item.human_category
          expect(mail.body.encoded).to include number_to_currency(clearing_item.total)
        end
      end
    end
  end

  describe "#confirmation_mail" do
    let(:mail) do
      BookingMailer.confirmation_mail \
        inquiry: inquiry,
        to:      inquiry.customer.email
    end
    let(:booking) { inquiry.booking }
    let(:villa_inquiry) { inquiry.villa_inquiry }
    let(:clearing) { inquiry.clearing }
    let(:boat_inquiry) { inquiry.boat_inquiry }
    let(:boat) { boat_inquiry.boat }
    let(:villa_clearing) { clearing.for_rentable(:villa) }
    let(:boat_clearing) { clearing.for_rentable(:boat) }

    before do
      customer.update phone: "0124234"

      allow(villa).to receive :attach_geocode
      villa.update \
        locality: "test locality",
        region:   "test region",
        country:  "test country",
        phone:    "23542343"
      villa.reload
      inquiry.reload
    end

    it "renders the localized subject" do
      expect(mail.subject).to eq "#{inquiry.number}: Auftragsbestätigung - Intervilla"
    end

    it_behaves_like "a Confirmation Mail"

    context "en" do
      alias_method :de_mail, :mail
      let(:mail) {
        inquiry
        I18n.with_locale(:en) {
          de_mail.tap(&:subject)
        }
      }

      it "renders en subject" do
        expect(mail.subject).to eq "#{inquiry.number}: Booking Confirmation - Intervilla"
      end

      it_behaves_like "a Confirmation Mail", :en
    end
  end

  shared_examples "a Review mail" do |locale = :de|
    it "renders the headers" do
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include customer.email
    end

    it "includes review information" do
      [
        h(customer.salutation),
        villa.name,
        edit_villa_review_url(
          id:        booking.review.token,
          villa_id:  villa.to_param,
          subdomain: locale == :en ? "en.self" : "www.self",
        ),
      ].each do |information|
        expect(mail.body.encoded).to include information
      end
    end
  end

  describe "#review" do
    let(:mail) do
      BookingMailer.review(
        inquiry: inquiry,
        to:      inquiry.customer.email,
      )
    end
    let(:booking) { inquiry.booking }
    let!(:review) { booking.inquiry.prepare_review }

    it "renders the localized subject" do
      expect(mail.subject).to eq "#{inquiry.number}: Ihr Urlaub mit Intervilla Florida"
    end

    it_behaves_like "a Review mail"

    context "with locale :en" do
      let(:mail) do
        inquiry
        I18n.with_locale :en do
          mail = BookingMailer.review(
            inquiry: inquiry,
            to:      inquiry.customer.email,
          )
          mail.subject
          mail
        end
      end

      it "renders the localized subject" do
        expect(mail.subject).to eq "#{inquiry.number}: Your vacation with Intervilla Florida"
      end

      it_behaves_like "a Review mail", :en
    end
  end

  describe "#travel_mail" do
    shared_examples "a Travel mail" do |locale|
      it "renders the headers" do
        expect(mail.from).to include "info@intervillas-florida.com"
        expect(mail.to).to include customer.email
      end

      it "includes booking information" do
        fmt = locale.to_s == "en" ? "%m/%d/%Y" : "%d.%m.%Y"
        [
          h(customer.salutation),
          villa.name,
          villa_inquiry.start_date.strftime(fmt),
          villa_inquiry.end_date.strftime(fmt),
          boat.display_name,
          boat_inquiry.start_date.strftime(fmt),
          boat_inquiry.end_date.strftime(fmt),
          booking.number,
          villa.safe_code,
          villa.manager.phone,
          boat.manager.phone,
        ].each do |information|
          expect(mail.body.encoded).to include information
        end
      end
    end

    let(:mail) do
      BookingMailer.travel_mail \
        inquiry: inquiry,
        to:      inquiry.customer.email
    end
    let(:villa_inquiry) { inquiry.villa_inquiry }
    let(:boat_inquiry) { inquiry.boat_inquiry }
    let(:boat) { boat_inquiry.boat }
    let(:booking) { inquiry.booking }

    it "renders the localized subject" do
      expect(mail.subject).to eq "#{inquiry.number}: 2 Wochen vor Reisebeginn - Intervilla"
    end

    it_behaves_like "a Travel mail"

    context "with locale :en" do
      let(:mail) do
        inquiry
        I18n.with_locale :en do
          mail = BookingMailer.travel_mail \
            inquiry: inquiry,
            to:      inquiry.customer.email
          mail.subject
          mail
        end
      end

      it "renders the localized subject" do
        expect(mail.subject).to eq "#{inquiry.number}: Pre-Travel Notification - Intervilla"
      end

      it_behaves_like "a Travel mail", :en
    end
  end
end
