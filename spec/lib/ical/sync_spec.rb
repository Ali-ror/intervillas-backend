require "rails_helper"

RSpec.describe Ical::Sync do
  let(:villa) { create :villa, :bookable }
  let(:calendar) { create :calendar, villa: villa }

  describe "#run" do
    subject(:sync) do
      Ical::Sync.new(events, calendar)
    end

    let(:file_path)  { "spec/fixtures/ical/smoobu_neu.ics" }
    let(:file)       { File.open(file_path) }
    let(:source_url) { "https://localhost/my.ics" }
    let(:events)     { Ical::Event.parse(file, source_url) }

    before do
      Timecop.travel Date.new(2019, 10, 1)
    end

    after do
      file.close
      Timecop.return
    end

    context "Neue Events" do
      before do
        expect(villa.blockings).to be_blank
        sync.run
      end

      it { expect(villa.blockings.count).to eq 1 }

      it do
        expect(villa.blockings).to include have_attributes(
          start_date:  Date.new(2019, 11, 1),
          end_date:    Date.new(2019, 11, 9),
          comment:     "Not available",
          calendar_id: calendar.id,
        )
      end

      context "mit einem Event" do
        let(:other_file) { File.open(other_file_path) }

        before do
          expect(villa.blockings.count).to eq 1

          Ical::Sync.new(Ical::Event.parse(other_file, source_url), calendar).run
        end

        after do
          other_file.close
        end

        context "Event hinzugefügt" do
          # enthält auch das Event aus smoobu_neu.ics
          let(:other_file_path) { "spec/fixtures/ical/smoobu_hinzu.ics" }

          # bestehendes Event wurde nicht dupliziert
          it { expect(villa.blockings.count).to eq 2 }

          it do
            expect(villa.blockings.reload).to include have_attributes(
              start_date:  Date.new(2019, 11, 27),
              end_date:    Date.new(2019, 12, 8),
              comment:     "Not available",
              calendar_id: calendar.id,
            )
          end

          context "Event entfernt" do
            let(:sync_date) { Date.new 2020, 2, 5 }

            before do
              expect(villa.blockings.count).to eq 2

              # nochmal smoobu_neu.ics einlesen, da hier das zweite Event nicht
              # enthalten ist
              Timecop.travel sync_date do
                file.rewind
                Ical::Sync.new(Ical::Event.parse(file, source_url), calendar).run
              end
            end

            # Event in der Vergangenheit bleibt erhalten -> Statistik
            it { expect(villa.blockings.count).to eq 2 }

            context "Event in der Zukunft" do
              let(:sync_date) { Date.new 2019, 2, 5 }

              # zweites Event wurde entfernt
              it { expect(villa.blockings.count).to eq 1 }

              it do
                expect(villa.blockings.reload).not_to include have_attributes(
                  start_date:  Date.new(2019, 11, 27),
                  end_date:    Date.new(2019, 12, 8),
                  comment:     "Not available",
                  calendar_id: calendar.id,
                )
              end
            end
          end
        end

        context "Event geändert" do
          context "Daten" do
            # enthält das Event aus smoobu_neu.ics
            let(:other_file_path) { "spec/fixtures/ical/smoobu_aktual.ics" }

            # bestehendes Event wurde nicht dupliziert
            it { expect(villa.blockings.count).to eq 1 }

            it do
              expect(villa.blockings.reload).to include have_attributes(
                start_date:  Date.new(2019, 11, 1),
                end_date:    Date.new(2019, 11, 10),
                comment:     "Not available",
                calendar_id: calendar.id,
              )
            end
          end

          context "UID" do
            # enthält das Event aus smoobu_neu.ics
            let(:other_file_path) { "spec/fixtures/ical/smoobu_aktual_uid.ics" }

            # bestehendes Event wurde nicht dupliziert
            it { expect(villa.blockings.count).to eq 1 }

            it do
              expect(villa.blockings.reload).to include have_attributes(
                start_date:  Date.new(2019, 11, 1),
                end_date:    Date.new(2019, 11, 9),
                comment:     "Not available",
                calendar_id: calendar.id,
              )
            end
          end

          context "missing UID" do
            # enthält das Event aus smoobu_neu.ics aber mit fehlender UID
            let(:other_file_path) { "spec/fixtures/ical/smoobu_missing_uid.ics" }

            # bestehendes Event wurde nicht dupliziert
            it { expect(villa.blockings.count).to eq 1 }

            it do
              expect(villa.blockings.reload).to include have_attributes(
                start_date:  Date.new(2019, 11, 1),
                end_date:    Date.new(2019, 11, 9),
                comment:     "Not available",
                calendar_id: calendar.id,
                ical_uid:    "20200102T184933Z@#{source_url}",
              )
            end
          end
        end
      end
    end

    shared_examples "Clash Handling" do
      let(:clash_date) { existing.start_date.strftime("%m/%Y") }

      it "creates a new blocking" do
        expect {
          sync.run
        }.to change(villa.blockings, :count).by(1)
      end

      it "delivers a collision mail" do
        expect {
          sync.run
        }.to change(ActionMailer::Base.deliveries, :count).by(1)

        expect(last_email).to have_attributes(
          subject: "Kollision Buchung #{existing.number} mit iCal-Kalender (#{clash_date})",
          to:      ["info@intervillas-florida.com"],
        )
      end
    end

    describe "Kollision mit Buchung" do
      include_examples "Clash Handling" do
        let!(:existing) do
          create_full_booking \
            villa:      villa,
            start_date: Date.new(2019, 11, 4),
            end_date:   Date.new(2019, 11, 15)
        end
      end

      it "erstellt Blocking und versendet Email nur ein mal" do
        expect {
          2.times { sync.run }
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
          .and change(villa.blockings, :count).by(1)
      end
    end

    describe "Kollision mit Blocking" do
      include_examples "Clash Handling" do
        let!(:existing) do
          create :blocking,
            villa:      villa,
            start_date: Date.new(2019, 11, 4),
            end_date:   Date.new(2019, 11, 15)
        end
      end
    end

    context "leere Events" do
      let(:file_path) { "spec/fixtures/ical/empty_events.ics" }

      it { expect(events).to be_empty }
    end
  end
end
