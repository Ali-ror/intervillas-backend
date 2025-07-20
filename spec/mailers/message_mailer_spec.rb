require "rails_helper"

RSpec.describe MessageMailer do
  let(:inquiry)  { create_full_booking_with_boat(boat_state: :optional, with_owner: true, with_manager: true).inquiry }
  let(:customer) { inquiry.customer }
  let(:villa)    { inquiry.villa }
  let(:booking)  { inquiry.booking }

  # test-specific variables
  let(:template)  { nil }
  let(:recipient) { nil }

  let(:message) { build :message, recipient:, inquiry:, template: }
  let(:mail)    { message.message_delivery recipient.email_addresses.first }
  let(:body)    { Capybara.string mail.body.encoded }

  describe "#owner_booking_message" do
    let(:owner) { villa.owner }
    let(:villa_inquiry) { inquiry.villa_inquiry }

    let(:recipient) { owner }
    let(:template) { :owner_booking_message }

    it "renders the headers" do
      expect(mail.subject).to eq "#{inquiry.number}: Booking Confirmation Information - Intervilla"
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include owner.email_addresses.first
    end

    it "includes booking details" do
      [
        "Booking Message #{booking.number}",
        "Vacation rental #{villa.name}",
        "Name #{customer.name}",
        "Rental period #{villa_inquiry.start_date} to #{villa_inquiry.end_date}",
        "Number of tenants #{villa_inquiry.persons}",
        "Total rental price € 1,120.00",
      ].each do |information|
        expect(body).to have_content(information)
      end
    end

    context "in USD" do
      let(:inquiry) { create_full_booking_with_boat(boat_state: :optional, with_owner: true, with_manager: true, currency: Currency::USD).inquiry }

      it "includes booking details" do
        expect(body).to have_content("Total rental price $ 1,491.00 (daily exchange rate)")
      end
    end
  end

  describe "#boat_owner_booking_message" do
    let(:boat_inquiry) { inquiry.boat_inquiry }
    let(:boat) { boat_inquiry.boat }
    let(:owner) { boat.owner }

    let(:recipient) { owner }
    let(:template) { :boat_owner_booking_message }

    it "renders the headers" do
      expect(mail.subject).to eq "#{inquiry.number}: Booking Confirmation Information - Intervilla"
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include owner.email_addresses.first
    end

    it "includes booking details" do
      [
        "Booking Message #{booking.number}",
        "Boat rental FL-#{boat.matriculation_number}",
        "Name #{customer.name}",
        "Rental period #{boat_inquiry.start_date} to #{boat_inquiry.end_date}",
        "Total rental price € 139.38",
      ].each do |information|
        expect(body).to have_content(information)
      end
    end
  end

  describe "#note_mail" do
    let(:manager) { villa.manager }
    let(:user)    { create :user, :with_password }

    let(:recipient) { manager }
    let(:template)  { :note_mail }
    let(:text)      { "Good news, everybody!" }
    let(:message)   { build :message, recipient:, inquiry:, template:, text: }

    before do
      manager.users << user
      manager.emails << user.email
      manager.save
      manager.reload
    end

    it "renders the headers" do
      expect(mail.subject).to eq "#{inquiry.number}: Buchungsnotiz - Intervilla"
      expect(mail.from).to include "info@intervillas-florida.com"
      expect(mail.to).to include manager.email_addresses.first
    end

    it "includes custom text" do
      expect(body).to have_content "Es wurde folgende Notiz zur Buchung #{booking.number} angelegt: #{text}"
    end

    it "includes customer" do
      [
        manager.title,
        manager.last_name,
        booking.number,
        villa.name,
        admin_booking_url(booking),
        "Mieter #{customer.name}",
        "E-Mail #{customer.email || './.'}",
        "Telefon-Nr. #{customer.phone || './.'}",
      ].each do |information|
        expect(body).to have_content(information)
      end
    end

    context "booked" do
      let(:text) { "foo\x03book" }

      it { expect(body).to have_content villa.name }
      it { expect(body).to have_content "Mieter #{customer.name}" }
    end

    context "cancelled" do
      let(:text) { "foo\x03cancel" }

      it { expect(body).to have_no_content villa.name }
      it { expect(body).to have_no_content "Mieter" }
    end

    context "dates changed" do
      let(:text) { "foo\x03dates" }

      it { expect(body).to have_content villa.name }
      it { expect(body).to have_content "Mieter" }
    end
  end
end
