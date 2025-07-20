require "rails_helper"

RSpec.describe Villa do
  it { is_expected.to have_one :inclusive_boat }
  it { is_expected.to have_and_belong_to_many :optional_boats }

  # TODO: Haus mit inklusivem Boot können keine optionalen Boote zugeordnet werden.
  # TODO: Haus mit optionalen Booten kann kein inklusives Boot zugeordnet werden.
end
