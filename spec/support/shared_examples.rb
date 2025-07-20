RSpec.shared_examples "validates_availability" do
  let(:clashing_booking) { create_full_booking }
  context "invalid" do
    let(:villa) { clashing_booking.villa }

    context "clashing booking" do
      it { expect(form).to have_error(:already_booked, on: :start_date) }
      it { expect(form).to have_error(:already_booked, on: :end_date) }
    end

    context "clashing blocking" do
      let!(:clashing_booking) { create :blocking }

      it { expect(form).to have_error(:already_booked, on: :start_date) }
      it { expect(form).to have_error(:already_booked, on: :end_date) }
    end
  end

  context "valid" do
    let(:villa) { create :villa }

    it { expect(form).not_to have_error(:already_booked, on: :start_date) }
    it { expect(form).not_to have_error(:already_booked, on: :end_date) }
  end
end

RSpec.shared_examples "validates_ends_after_start" do
  context "invalid" do
    let(:end_date) { Date.yesterday }

    it { expect(form).to have_error(:after_start, on: :end_date) }
  end

  context "valid" do
    let(:end_date) { Date.tomorrow + 1.day }

    it { expect(form).not_to have_error(:after_start, on: :end_date) }
  end
end
