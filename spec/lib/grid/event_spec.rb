require "rails_helper"

RSpec.describe Grid::Event do
  subject {
    Grid::Event.new content,
      start_date: start_date,
      end_date:   end_date
  }

  let(:content)     { "somthing" }
  let(:start_incl)  { true }
  let(:end_incl)    { true }

  # 2016 == leap year!
  let(:start_date)  { DateTime.new 2016, 2, 26, (start_incl ? 8 : 16) }
  let(:end_date)    { DateTime.new 2016, 3, 4,  (end_incl   ? 16 : 8) }

  # hier ist leider kein Zugriff auf die let-Variablen start/end_incl möglich,
  # daher müssen die einmal manuell übergeben werden...
  shared_examples "overlap detection" do |sincl, eincl|
    {
      # immer wahr:
      [[2016,  2, 26], [2016,  3,  4]] => [true,  "same dates"],
      [[2016,  2, 26], [2016,  3,  1]] => [true,  "same start date, but shorter"],
      [[2016,  2, 26], [2016,  3,  7]] => [true,  "same start date, but longer"],
      [[2016,  2, 27], [2016,  3,  4]] => [true,  "same end date, but shorter"],
      [[2016,  2, 25], [2016,  3,  4]] => [true,  "same end date, but longer"],
      [[2016,  2, 20], [2016,  2, 27]] => [true,  "simple overlap at start"],
      [[2016,  3, 1], [2016, 3, 10]]   => [true, "simple overlap at end"],
      [[2016,  2, 28], [2016,  3, 2]]  => [true, "subject includes other"],
      [[2016,  2, 25], [2016,  3, 10]] => [true, "other includes subject"],
      [[2015, 12, 30], [2016,  1, 1]]  => [false, "distinctively before"],
      [[2016,  5, 5], [2016, 7,  7]]   => [false, "distinctively after"],

      # hängt von incl-Status ab:
      [[2016,  1, 30], [2016, 2, 26]]  => [sincl || eincl, "bordering on start date"],
      [[2016,  3, 4], [2016,  4, 1]]   => [sincl || eincl, "bordering on end date"],
    }.each do |(sdate, edate), (overlap_expectation, example_name)|
      it "when #{example_name}" do
        event = Grid::Event.new content,
          start_date: DateTime.new(*sdate, (sincl ? 8 : 16)),
          end_date:   DateTime.new(*edate, (eincl ? 16 : 8))

        expect(subject.overlaps_with?(event)).to be overlap_expectation
        expect(event.overlaps_with?(subject)).to be overlap_expectation
      end
    end
  end

  context "start/end dates are fully included" do
    let(:start_incl)  { true }
    let(:end_incl)    { true }

    its(:start_date)  { is_expected.to eq DateTime.new(2016, 2, 26, 8) }
    its(:end_date)    { is_expected.to eq DateTime.new(2016, 3, 4, 16) }
    its(:half_days)   { is_expected.to eq 16 }
    its(:full_days)   { is_expected.to eq 8 }
    its(:single?)     { is_expected.to be false }
    its(:start_incl?) { is_expected.to be start_incl }
    its(:end_incl?)   { is_expected.to be end_incl }

    it_behaves_like "overlap detection", true, true

    context "start/end date are the same" do
      let(:end_date)  { start_date }

      its(:half_days) { is_expected.to eq 1 }
      its(:full_days) { is_expected.to eq 0 }
      its(:single?)   { is_expected.to be true }
    end
  end

  context "start/end date are only partially included" do
    let(:start_incl)  { false }
    let(:end_incl)    { false }

    its(:start_date)  { is_expected.to eq DateTime.new(2016, 2, 26, 16) }
    its(:end_date)    { is_expected.to eq DateTime.new(2016, 3, 4, 8) }
    its(:half_days)   { is_expected.to eq 14 }
    its(:full_days)   { is_expected.to eq 7 }
    its(:single?)     { is_expected.to be false }
    its(:start_incl?) { is_expected.to be start_incl }
    its(:end_incl?)   { is_expected.to be end_incl }

    it_behaves_like "overlap detection", false, false

    context "#restrict! to end of month" do
      before { subject.restrict! nil, start_date.end_of_month }

      its(:start_date)  { is_expected.to eq DateTime.new(2016, 2, 26, 16) }
      its(:end_date)    { is_expected.to eq DateTime.new(2016, 2, 29, 23, 59, 59).end_of_minute }
      its(:half_days)   { is_expected.to eq 7 }
      its(:full_days)   { is_expected.to eq 3 }
      its(:single?)     { is_expected.to be false }
      its(:start_incl?) { is_expected.to be start_incl }
      its(:end_incl?)   { is_expected.to be true }
    end

    context "#restrict! to beginning of month" do
      before { subject.restrict! end_date.beginning_of_month, nil }

      its(:start_date)  { is_expected.to eq DateTime.new(2016, 3,  1,  0) }
      its(:end_date)    { is_expected.to eq DateTime.new(2016, 3,  4,  8) }
      its(:half_days)   { is_expected.to eq 7 }
      its(:full_days)   { is_expected.to eq 3 }
      its(:single?)     { is_expected.to be false }
      its(:start_incl?) { is_expected.to be true }
      its(:end_incl?)   { is_expected.to be end_incl }
    end
  end

  describe "#half_days" do
    {
      [[2016, 9, 2, 0], [2016, 9, 2, 8]]           => [1, 0, "½ day, aligned ante meridiem"],
      [[2016, 9, 2, 16], [2016, 9, 2, 23, 59, 59]] => [1, 0, "½ day, aligned post meridiem"],
      [[2016, 9, 3, 0], [2016, 9, 3, 23, 59, 59]]  => [2, 1, "½+½ days"],
      [[2016, 9, 3, 16], [2016, 9, 4, 8]]          => [2, 1, "1 day"],
      [[2016, 9, 4, 16], [2016, 9, 5, 23, 59, 59]] => [3, 1, "½+1 days"],
      [[2016, 9, 5,  0], [2016, 9, 6, 8]]          => [3, 1, "1+½ days"],
      [[2016, 9, 2,  0], [2016, 9, 3, 23, 59, 59]] => [4, 2, "2 days"],
      [[2016, 9, 4, 16], [2016, 9, 6, 8]]          => [4,  2, "½+1+½ days"],
      [[2016, 9, 1, 8], [2016, 9, 4, 16]]          => [8,  4, "4 days"],
      [[2016, 9, 1, 16], [2016, 9, 6, 8]]          => [10, 5, "½+4+½ days"],
    }.each do |(sdate, edate), (half_days, full_days, example_name)|
      it "expect #{half_days} half days when given #{example_name}" do
        event = Grid::Event.new "",
          start_date: DateTime.new(*sdate),
          end_date:   DateTime.new(*edate)

        expect(event.half_days).to eq half_days
        expect(event.full_days).to eq full_days
      end
    end
  end
end
