module Bookings::External
  extend ActiveSupport::Concern

  Error = Class.new(StandardError)

  included do
    # Filtert externe Buchungen für die Summaries heraus
    scope :internal, -> { joins(:inquiry).where(inquiries: { external: false }) }
  end
end
