module RentableInquiry::Availability
  extend ActiveSupport::Concern

  included do
    delegate :still_available?, :reserved?, to: :availability
  end

  def availability
    ::Availability.new(self)
  end
end
