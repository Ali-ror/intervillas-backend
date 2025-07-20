module Inquiry::Discounts
  extend ActiveSupport::Concern

  included do
    has_many :discounts, autosave: true, dependent: :destroy
  end
end
