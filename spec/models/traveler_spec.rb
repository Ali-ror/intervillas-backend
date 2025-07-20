require "rails_helper"

RSpec.describe Traveler do
  %w[start_date born_on first_name last_name].each do |col|
    it { is_expected.to have_db_column(col) }
  end

  it { is_expected.to belong_to :inquiry }

  describe "age calculation" do
    let(:born_on) { "2008-08-08".to_datetime }

    shared_examples "performing calculations" do |ref_date, age, category, has_birthday|
      describe "on #{ref_date}" do
        subject(:traveler) do
          build :traveler,
            born_on:    born_on,
            start_date: ref_date.to_datetime
        end

        # age and birthday take a reference date
        it "age should be #{age}" do
          expect(traveler.age(traveler.start_date)).to eq age
        end

        might_have_birthday = has_birthday ? "has birthday" : "hasn't birthday"
        it might_have_birthday do
          expect(traveler.birthday?(traveler.start_date)).to be !!has_birthday
        end

        # price_category operates directly on start_date
        it "category should be #{category}" do
          expect(traveler.price_category_by_age).to be category
        end
      end
    end

    {
      "2008-08-08" => [0, :children_under_6, true],
      "2008-08-09" => [0, :children_under_6],

      "2009-08-07" => [0, :children_under_6],
      "2009-08-08" => [1, :children_under_6, true],
      "2009-08-09" => [1, :children_under_6],

      "2014-08-07" => [5, :children_under_6],
      "2014-08-08" => [6, :children_under_6, true],
      "2014-08-09" => [6, :children_under_12],

      "2020-08-07" => [11, :children_under_12],
      "2020-08-08" => [12, :children_under_12, true],
      "2020-08-09" => [12, :adults],
    }.each do |ref_date, (age, cat, bday)|
      include_examples "performing calculations", ref_date, age, cat, bday
    end

    context "born on Feb 29" do
      let(:born_on) { "2008-02-29".to_datetime }

      {
        "2008-02-29" => [0, :children_under_6, true],
        "2008-08-09" => [0, :children_under_6],

        "2014-02-28" => [5, :children_under_6],
        "2014-03-01" => [6, :children_under_6, true],
        "2014-03-02" => [6, :children_under_12],

        "2020-02-28" => [11, :children_under_12],
        "2020-02-29" => [12, :children_under_12, true],
        "2020-03-01" => [12, :adults],
      }.each do |ref_date, (age, cat, bday)|
        include_examples "performing calculations", ref_date, age, cat, bday
      end
    end
  end

  describe "factory" do
    describe ":children_under_12" do
      subject(:traveler) { create :traveler, :children_under_12 }

      it { is_expected.to be_valid }
      its(:price_category_by_age) { is_expected.to eq :children_under_12 }

      context "with start_date" do
        subject(:traveler) { create :traveler, :children_under_12, start_date: 10.years.from_now }

        it { is_expected.to be_valid }
        its(:price_category_by_age) { is_expected.to eq :children_under_12 }
      end
    end
  end
end
