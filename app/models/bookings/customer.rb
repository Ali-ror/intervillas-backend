module Bookings::Customer
  extend ActiveSupport::Concern

  included do
    has_one :customer, through: :inquiry
  end
end
