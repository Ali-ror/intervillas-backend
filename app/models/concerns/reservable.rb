module Reservable
  extend ActiveSupport::Concern

  included do
    has_one :reservation, class_name: "::Reservation", foreign_key: :inquiry_id, primary_key: :inquiry_id
  end
end
