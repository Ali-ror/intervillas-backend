require "rails_helper"

RSpec.describe Inquiry, vcr: { cassette_name: "villa/geocode" } do # rubocop:disable RSpec/SpecFilePathFormat
  let(:inquiry) { booking.inquiry }
  let(:booking) { create_full_booking }

  let(:villa_owner)   { create(:contact) }
  let(:villa_manager) { create(:contact) }
  let(:boat_owner)    { create(:contact) }
  let(:boat_manager)  { create(:contact) }

  let(:messages)      { inquiry.messages.where(template: "note_mail") }
  let(:confirmations) { inquiry.messages.where(template: %w[owner_booking_message boat_owner_booking_message]) }

  def change_travel_dates!(skip: false)
    t = inquiry.travelers.first

    updates = {
      travelers_attributes:     [{ id: t.id, start_date: t.start_date - 1.day }],
      villa_inquiry_attributes: ({ skip_notification: true } if skip),
    }.compact

    inquiry.update(updates)
  end

  before do
    # XXX: inquiry.villa.update would require reloading villa in villa_inquiry
    inquiry.villa_inquiry.villa.update owner: villa_owner, manager: villa_manager
    inquiry.boat_inquiry&.boat&.update owner: boat_owner, manager: boat_manager
  end

  it "doesn't send mails when nothing changes" do
    expect {
      inquiry.save!
    }.not_to change(messages, :count)
  end

  it "can skip sending notifications" do
    expect {
      change_travel_dates!(skip: true)
    }.not_to change(messages, :count)
  end

  it "sends note mails to villa owner/manager if travel dates change" do
    expect {
      change_travel_dates!
    }.to change(messages, :count).by(2)

    [villa_owner, villa_manager].each do |contact|
      message = messages.find_by(recipient: contact)
      expect(message).to have_attributes text: "An- oder Abreisedatum wurde geändert.\x03dates"
    end
  end

  it "sends note mails to villa owner/manager if villa changes" do
    new_villa = create(:villa, :with_owner, :with_manager)
    old_villa = inquiry.villa_inquiry.villa

    expect {
      inquiry.update villa_inquiry_attributes: { id: inquiry.villa_inquiry.id, villa_id: new_villa.id }
    }.to change(messages, :count).by(3)
      .and change(confirmations, :count).by(1)

    [villa_owner, villa_manager].each do |contact|
      message = messages.find_by(recipient: contact)
      expect(message).to have_attributes text: "Villa #{old_villa.admin_display_name} wurde storniert.\x03cancel"
    end

    message = messages.find_by(recipient: new_villa.manager)
    expect(message).to have_attributes text: "Villa #{new_villa.admin_display_name} wurde neu gebucht.\x03book"

    message = confirmations.find_by(recipient: new_villa.owner)
    expect(message).to have_attributes text: nil
  end

  it "only sends booking/cancellation mail, even if travel dates change" do
    new_villa = create(:villa, :with_owner, :with_manager, :bookable)
    old_villa = inquiry.villa_inquiry.villa

    expect {
      t = inquiry.travelers.first
      inquiry.update(
        villa_inquiry_attributes: { id: inquiry.villa_inquiry.id, villa_id: new_villa.id },
        travelers_attributes:     [{ id: t.id, start_date: t.start_date - 1.day }],
      )
    }.to change(messages, :count).by(3)
      .and change(confirmations, :count).by(1)

    expect(messages.where("text like ?", "An- oder Abreisedatum wurde geändert.%").count).to be 0

    [villa_owner, villa_manager].each do |contact|
      message = messages.find_by(recipient: contact)
      expect(message).to have_attributes text: "Villa #{old_villa.admin_display_name} wurde storniert.\x03cancel"
    end

    message = messages.find_by(recipient: new_villa.manager)
    expect(message).to have_attributes text: "Villa #{new_villa.admin_display_name} wurde neu gebucht.\x03book"

    message = confirmations.find_by(recipient: new_villa.owner)
    expect(message).to have_attributes text: nil
  end

  it "sends a booking mail for newly added boats" do
    boat = create(:boat, :with_owner, :with_manager)

    expect {
      inquiry.create_boat_inquiry! \
        boat:,
        start_date: inquiry.villa_inquiry.start_date + 1.day,
        end_date:   inquiry.villa_inquiry.end_date - 1.day
    }.to change(messages, :count).by(1)
      .and change(confirmations, :count).by(1)

    expect(confirmations.find_by(recipient: boat.owner)).to have_attributes(
      template: "boat_owner_booking_message",
      text:     nil,
    )
    expect(messages.find_by(recipient: boat.manager)).to have_attributes(
      template: "note_mail",
      text:     "Boot #{boat.admin_display_name} wurde hinzugefügt.\x03book",
    )
  end

  context "without contacts" do
    let(:villa_owner)   { nil }
    let(:villa_manager) { nil }

    it "doesn't send note mails" do
      expect {
        change_travel_dates!
      }.not_to change(Message, :count)
    end
  end

  context "contact without email addresses" do
    let(:villa_manager) { create(:contact, emails: []) }
    let(:villa_owner)   { create(:contact, emails: []) }

    it "doesn't send note mails" do
      expect {
        change_travel_dates!
      }.not_to change(messages, :count)
    end
  end

  context "with same contact for boat and villa" do
    let(:villa_manager) { villa_owner }

    # TODO: we might want to de-duplicate these mails
    it "sends two note mails to the same recipient" do
      scope = messages.where(recipient: villa_owner)
      expect {
        change_travel_dates!
      }.to change(scope, :count).by(2)

      expect(scope.last(2)).to all have_attributes(text: "An- oder Abreisedatum wurde geändert.\x03dates")
    end
  end

  context "with boat" do
    let(:booking)      { create_full_booking_with_boat boat_state: :optional }
    let(:boat_inquiry) { inquiry.boat_inquiry }

    it "notifies boat owner/manager about removal" do
      boat = boat_inquiry.boat

      expect {
        boat_inquiry.destroy
      }.to change(messages, :count).by(2) # villa_owner/manager are not notified

      text = "Boot #{boat.admin_display_name} wurde entfernt.\x03cancel"
      [boat_owner, boat_manager].each do |contact|
        message = messages.find_by(recipient: contact)
        expect(message).to have_attributes(text:)
      end
    end

    it "doesn't notify boat owner, if villa changes" do
      expect {
        change_travel_dates!
      }.not_to change(messages.where(recipient: [boat_manager, boat_owner]), :count)
    end

    it "sends note mails to boat owner/manager if boat changes" do
      new_boat = create(:boat, :with_owner, :with_manager)
      old_boat = inquiry.boat_inquiry.boat

      expect {
        inquiry.update boat_inquiry_attributes: { id: inquiry.boat_inquiry.id, boat_id: new_boat.id }
      }.to change(messages, :count).by(3)
        .and change(confirmations, :count).by(1)

      [boat_owner, boat_manager].each do |contact|
        message = messages.find_by(recipient: contact)
        expect(message).to have_attributes text: "Boot #{old_boat.admin_display_name} wurde entfernt.\x03cancel"
      end

      expect(messages.find_by(recipient: new_boat.manager)).to have_attributes(
        template: "note_mail",
        text:     "Boot #{new_boat.admin_display_name} wurde hinzugefügt.\x03book",
      )
      expect(confirmations.find_by(recipient: new_boat.owner)).to have_attributes(
        template: "boat_owner_booking_message",
        text:     nil,
      )
    end

    it "can skip sending notifications" do
      expect {
        inquiry.update boat_inquiry_attributes: {
          id:                inquiry.boat_inquiry.id,
          start_date:        inquiry.boat_inquiry.start_date + 1.day,
          end_date:          inquiry.boat_inquiry.start_date - 1.day,
          skip_notification: true,
        }
      }.not_to change(messages, :count)
    end
  end
end
