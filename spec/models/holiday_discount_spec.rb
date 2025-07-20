require "rails_helper"

RSpec.describe HolidayDiscount do
  %w[villa_id days_before days_after description percent].each do |col|
    it { is_expected.to have_db_column col }
  end

  it { is_expected.to belong_to(:villa).optional }
  it { is_expected.to belong_to(:boat).optional }

  %w[days_before days_after description percent].each do |col|
    it { is_expected.to validate_presence_of col }
  end

  %w[days_before days_after percent].each do |col|
    it { is_expected.to validate_numericality_of col }
  end

  it { is_expected.not_to allow_value(-10).for(:percent) }
  it { is_expected.not_to allow_value(110).for(:percent) }
  it { is_expected.not_to allow_value(-10).for(:days_after) }
  it { is_expected.not_to allow_value(-10).for(:days_before) }
end
