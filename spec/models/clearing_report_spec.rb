require "rails_helper"

RSpec.describe ClearingReport do
  it { validate_presence_of(:reference_month) }

  describe "hooks" do
    it "after_create creates a delivery job" do
      expect { create(:clearing_report) }.to change(MailWorker.jobs, :size).by(1)
    end

    it "after_save doesn't create a delivery job" do
      report = create(:clearing_report)
      expect { report.touch }.not_to change(MailWorker.jobs, :size)
    end
  end

  # prüft v.a. ob window function erwartungsgemäß funktioniert
  describe ".by_last_mail_sent_in scope" do
    subject { ClearingReport.by_last_mail_sent_in(ref) }

    let(:ref) { Date.current.beginning_of_month }

    its(:count) { is_expected.to be 0 }

    context "with records" do
      let(:contact) { create :contact }
      let!(:report) { create :clearing_report, contact: contact, reference_month: ref }

      its(:count) { is_expected.to be 1 }
      it { is_expected.to contain_exactly report }

      context "from other contacts" do
        let!(:other) { create :clearing_report, reference_month: ref }

        its(:count) { is_expected.to be 2 }
        it { is_expected.to contain_exactly(report, other) }
      end

      context "multiple" do
        let(:age) { 2.days.ago }

        before { create_list :clearing_report, 2, contact: contact, reference_month: ref, created_at: age }

        its(:count) { is_expected.to be 1 }
        it { is_expected.to contain_exactly report }

        context "from other contacts" do
          let!(:other) { create :clearing_report, reference_month: ref }

          its(:count) { is_expected.to be 2 }
          it { is_expected.to contain_exactly(report, other) }
        end
      end
    end
  end

  describe "#clearing" do
    subject { report.clearing }

    let(:contact) { create :contact }
    let(:report)  { create :clearing_report, contact: contact }

    it { is_expected.to be_a ClearingReport::Clearing }
    its(:contact)     { is_expected.to be report.contact }
    its(:month)       { is_expected.to be report.reference_month }
    its(:inquiry_ids) { is_expected.to be_empty }

    context "contact has villa" do
      let!(:villa) { create :villa, :bookable, owner: contact }

      its(:inquiry_ids) { is_expected.to be_empty }

      context "with not-billed bookings" do
        let!(:booking) { create_full_booking(villa: villa, start_date: 1.month.ago) }

        its(:inquiry_ids) { is_expected.to be_empty }

        context "when billed" do
          before do
            create :villa_billing, villa_inquiry: booking.villa_inquiry
            booking.update_attribute :summary_on, report.reference_month
          end

          its(:inquiry_ids) { is_expected.to eq [booking.inquiry_id] }
        end

        context "with multiple bookings" do
          let!(:other) { [2, 3].map { |i| create_full_booking(villa: villa, start_date: i.month.ago) } }

          its(:inquiry_ids) { is_expected.to be_empty }

          context "partially billed" do
            before do
              [booking, other[1]].each do |b|
                create :villa_billing, villa_inquiry: b.villa_inquiry
                b.update_attribute :summary_on, report.reference_month
              end
            end

            its(:inquiry_ids) { is_expected.to contain_exactly(other[1].inquiry_id, booking.inquiry_id) }
          end

          context "billed in different months" do
            before do
              [booking, *other].each_with_index do |b, i|
                create :villa_billing, villa_inquiry: b.villa_inquiry
                b.update_attribute :summary_on, (1 - i).months.ago.beginning_of_month.to_date
              end
            end

            its(:inquiry_ids) { is_expected.to contain_exactly other[0].inquiry_id }
          end
        end
      end
    end

    # XXX:  #with_compiled_pdf könnte man noch testen, aber das sollte schon
    #       in den Billing-Specs passiert sein
  end
end
