require "rails_helper"

RSpec.describe AdminMailer do
  let(:booking) { create_full_booking }
  let(:blocking) { create :blocking, :with_calendar, villa: booking.villa }
  let!(:mail) { AdminMailer.clash(booking, blocking) }

  it { expect(mail.subject).to match(/Kollision Buchung IV-E?\d+ mit iCal-Kalender/) }
  it { expect(mail.to).to include "info@intervillas-florida.com" }

  describe "body" do
    subject(:body) { Capybara.string(mail.body.encoded) }

    it { expect(body).to have_link(booking.number, href: edit_admin_booking_url(booking)) }
    it { expect(body).to have_link(blocking.number, href: edit_admin_blocking_url(blocking)) }
  end
end
