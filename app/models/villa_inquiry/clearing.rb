module VillaInquiry::Clearing
  extend ActiveSupport::Concern

  included do
    after_create :create_clearing_items
    attr_accessor :skip_clearing_items

    delegate :booked?,
      to: :inquiry

    has_many :clearing_items,
      foreign_key: %i[inquiry_id villa_id]
  end

  def clearing
    ::Clearing::Villa.new(clearing_items)
  end

  # Für die Specs
  def refresh_clearing_items
    clearing_items.destroy_all

    create_clearing_items
  end

  # initiale Abrechnungs-Posten erstellen
  def create_clearing_items
    return true if skip_clearing_items

    clearing_builder.save_to(inquiry)
    clearing_items.reload
  end

  def clearing_builder
    villa_params = ::Clearing::VillaParams.from_villa_inquiry(self)

    ::Clearing::Villa::Builder.new(villa_params, inquiry: inquiry).tap(&:build)
  end
end
