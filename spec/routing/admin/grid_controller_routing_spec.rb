require "rails_helper"

RSpec.describe Admin::GridController do
  it {
    is_expected.to route(:get, "/admin/grid/2000/42").to \
      action:  "index",
      variant: "grid",
      year:    "2000",
      month:   "42"
  }

  it {
    is_expected.to route(:get, "/admin/grid/slice").to \
      action:  "index",
      variant: "slice"
  }

  it {
    is_expected.to route(:get, "/admin/grid/slice/2000-04-04").to \
      action:     "index",
      variant:    "slice",
      start_date: "2000-04-04"
  }

  it {
    is_expected.to route(:get, "/admin/grid/slice/2000-04-04/2020-42-53").to \
      action:     "index",
      variant:    "slice",
      start_date: "2000-04-04",
      end_date:   "2020-42-53"
  }

  it { is_expected.not_to route(:get, "/admin/grid/foo/bar").to(action: "index") }
end
