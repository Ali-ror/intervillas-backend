require "rails_helper"

RSpec.describe Payment do
  it { is_expected.to have_db_column(:inquiry_id).of_type(:integer) }
  it { is_expected.to have_db_column(:scope).of_type(:string) }
  it { is_expected.to have_db_column(:sum).of_type(:decimal) }
  it { is_expected.to have_db_column(:paid_on).of_type(:date) }

  it { is_expected.to belong_to :inquiry }
  it { is_expected.to allow_value(nil).for(:scope) }
end
