module Bookings::Clearing
  extend ActiveSupport::Concern

  included do
    delegate :clearing, :clearing_items, to: :inquiry
    delegate :create_clearing_items, to: :villa_inquiry

    before_create do
      self.exchange_rate = Setting.exchange_rate_usd
    end
  end
end
