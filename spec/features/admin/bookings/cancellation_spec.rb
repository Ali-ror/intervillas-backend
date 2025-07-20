require "rails_helper"

RSpec.feature "Cancellations", :js do
  include_context "as_admin"

  shared_examples "cancels booking" do |curr|
    let(:boat_manager) { create :contact }

    let(:note_recipients) {
      [
        villa_inquiry.villa.owner,
        villa_inquiry.villa.manager,
        boat_inquiry.boat.owner,
        boat_inquiry.boat.manager,
      ].compact.flat_map(&:email_addresses)
    }

    before do
      boat_inquiry.boat.update! manager: boat_manager
    end

    context "cancels booking", :vcr do
      include_context "editable booking with boat", curr do
        scenario do
          visit edit_admin_booking_path(booking)

          expect(Message.count).to be 1 # adding boat
          Message.delete_all
          ActionMailer::Base.deliveries.clear

          within ".panel", text: "Löschen/Stornieren" do
            click_on "Storno anlegen"
          end

          within ".panel", text: "Buchung/Anfrage stornieren" do
            fill_in "Stornierungsgrund", with: "Kunde hat wegen Corona abgesagt"
            click_on "Storno anlegen"
            expect(page).to have_content "Buchung/Anfrage #{booking.number} erfolgreich storniert"

            click_on "Storno anzeigen"
          end

          expect(page).to have_content "Kunde hat wegen Corona abgesagt"

          expect(booking.inquiry.messages.where(template: "note_mail").count).to be note_recipients.size
          expect(ActionMailer::Base.deliveries.size).to be note_recipients.size

          recipients, subjects, bodies = ActionMailer::Base.deliveries.each_with_object([[], [], []]) do |mail, memo|
            memo[0].push(*mail.to)
            memo[1] << mail.subject
            memo[2] << Capybara.string(mail.body.decoded)
          end

          expect(recipients).to match note_recipients
          expect(bodies).to all have_content "Kunde hat wegen Corona abgesagt"
          expect(subjects).to all eq "#{booking.number}: Buchungsnotiz - Intervilla"
        end
      end
    end

    context "restores booking" do
      let(:cancellation) {
        booking.inquiry.tap { |inquiry|
          inquiry.cancel! reason: "Kunde hatte mehrere Angebote eingeholt"
          ActionMailer::Base.deliveries.clear
        }.cancellation
      }

      include_context "editable booking with boat", curr do
        scenario do
          visit admin_cancellation_path(cancellation)
          expect(Booking.find_by(inquiry_id: cancellation.inquiry_id)).to be_nil

          expect(page).to have_content "Kunde hatte mehrere Angebote eingeholt"
          click_on "bearbeiten"

          within ".panel", text: "Stornierung zurücknehmen" do
            click_on "Buchung wiederherstellen"
          end

          within ".panel", text: "Storno zurücknehmen" do
            click_on "Buchung wiederherstellen"
            expect(page).to have_content "Buchung #{cancellation.number} erfolgreich wiederhergestellt"

            click_on "Buchung anzeigen"
          end

          expect(page).to have_content "Löschen/Stornieren"

          expect(ActionMailer::Base.deliveries.size).to be 0
          expect(Cancellation.find_by(inquiry_id: booking.inquiry_id)).to be_nil
          expect(Booking.find_by(inquiry_id: booking.inquiry_id)).not_to be_nil

          expect(page).to have_no_css "#price_table.refreshing"
        end
      end
    end
  end

  context Currency::EUR do
    include_examples "cancels booking", Currency::EUR
  end

  context Currency::USD do
    include_examples "cancels booking", Currency::USD
  end
end
