require "rails_helper"

RSpec.describe Grid::Row do
  subject           { row }

  let(:content)     { "test content" }
  let(:start_date)  { Date.new(2016, 4, 1) }
  let(:end_date)    { Date.new(2016, 4, 30) }

  let(:row)         { Grid::Row.new content, start_date, end_date }

  its(:empty?) { is_expected.to be true }

  describe "#header" do
    subject       { row.header }

    its(:to_s)    { is_expected.to eq content }
    its(:span)    { is_expected.to be 1 }
    its(:empty?)  { is_expected.to be false }
  end

  describe "#<<" do
    it "rejects non-events" do
      expect { subject << "string" }.not_to raise_error
      expect(subject.events).to eq []
      expect(subject.empty?).to be true
    end

    [[0, 0], [1, 0], [0, 1], [10, 10]].each do |start_offset, end_offset|
      it "accepts events matching date range (offset +#{start_offset}/-#{end_offset})" do
        e = Grid::Event.new "string",
          start_date: start_date + start_offset,
          end_date:   end_date - end_offset

        subject << e
        expect(subject.events).to include e
        expect(subject.empty?).to be false
      end

      if start_offset > 0 || end_offset > 0
        it "rejects events slightly out of range (-#{start_offset}/+#{end_offset})" do
          e = Grid::Event.new "string",
            start_date: start_date - start_offset,
            end_date:   end_date + end_offset

          subject << e
          expect(subject.events).not_to include e
          expect(subject.empty?).to be true
        end
      end
    end
  end

  describe "#add_rentable_inquiry" do
    {
      # boat days (each day full)
      [[2016, 3, 10, 8], [2016, 3, 20, 16]] => ["Boat", false, 0], # out of range (before start)
      [[2016, 3, 10, 8], [2016, 4, 1, 16]]  => ["Boat", true, 1], # 1 day overlap on April 1st
      [[2016, 3, 25, 8], [2016, 4, 20, 16]] => ["Boat", true,  20], # overlap on start
      [[2016, 4, 10, 8], [2016, 4, 20, 16]] => ["Boat", true,  11], # completely covered
      [[2016, 4, 25, 8], [2016, 5, 6, 16]]  => ["Boat", true, 6], # overlap on end
      [[2016, 5, 1, 8], [2016, 5, 6, 16]]   => ["Boat", false, 0], # out of range (after end)

      # villa days (start/end count only half)
      [[2016, 3, 10, 16], [2016, 3, 20, 8]] => ["Villa", false, 0],
      [[2016, 3, 10, 16], [2016, 4, 1, 8]]  => ["Villa", true, 0], # half a day on April 1st
      [[2016, 3, 25, 16], [2016, 4, 20, 8]] => ["Villa", true,  19], # start full, end not
      [[2016, 4, 10, 16], [2016, 4, 20, 8]] => ["Villa", true,  10], # both not full
      [[2016, 4, 25, 16], [2016, 5, 6, 8]]  => ["Villa", true, 5], # end full, start not
      [[2016, 5, 1, 16], [2016, 5, 6, 8]]   => ["Villa", false, 0],
    }.each do |(estart, eend), (type, included, full_days)|
      estart = DateTime.new(*estart)
      eend   = DateTime.new(*eend)

      it "adds #{full_days}d for #{type} inquiry from #{estart} to #{eend}" do
        inq = double "#{type}Inquiry"
        allow(inq).to receive(:start_datetime).and_return(estart)
        allow(inq).to receive(:end_datetime).and_return(eend)

        subject.add_rentable_inquiry inq

        if included
          expect(subject.empty?).to be false
          expect(subject.events.first.full_days).to eq full_days
        else
          expect(subject.empty?).to be true
        end
      end
    end
  end
end
