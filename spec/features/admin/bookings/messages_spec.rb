require "rails_helper"

RSpec.feature "Messages", :js do
  include_context "as_admin"

  shared_examples "send message" do |curr|
    context curr do
      include_context "editable booking with boat", curr

      context "with Boat" do
        {
          "Eigentümer (Haus)" => "Buchungsbestätigung an Eigentümer",
          "Eigentümer (Boot)" => "Buchungsbestätigung an Boot-Eigentümer",
          "Hausverwaltung"    => "an Hausverwaltung",
          "Bootverwaltung"    => "an Bootsverwaltung",
        }.each do |tab_name, mailing|
          context "#{mailing} senden", :vcr do
            let(:boat) { booking.boat }

            before do
              boat.manager = create :contact
              boat.save
            end

            scenario do
              visit edit_admin_booking_path(booking)

              click_on "Kommunikation"
              within "#communication" do
                execute_script "window.scrollTo(0,00)"
                click_on tab_name
                within ".tab-pane", text: mailing do
                  fill_in "Text", with: "foobar Text"
                  click_on "versenden"
                end
              end

              click_on "Kommunikation"
              within "#communication" do
                execute_script "window.scrollTo(0,0)"
                click_on "Alle"
                within ".tab-pane", text: "Nachrichten" do
                  expect(page).to have_content "foobar Text"
                end
              end

              expect(page).to have_content "Nachricht wird in Kürze versendet"
              expect(page).not_to have_selector ".refreshing"
            end
          end
        end
      end
    end
  end

  context Currency::EUR do
    include_examples "send message", Currency::EUR
  end

  context Currency::USD do
    include_examples "send message", Currency::USD
  end
end
