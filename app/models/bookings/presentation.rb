#
# Sammlung von Methoden, die primär der Darstellung dienen (sei es für SEO-URLs
# Kalender-Infos oder Mail-Inhalte)
#
module Bookings::Presentation
  extend ActiveSupport::Concern
  include Inquiry::Presentation

  delegate :salutation, to: :customer
  delegate :number, :rentable_names, to: :inquiry

  def to_s
    <<~MESSAGE
      von #{name}
      fur #{villa.name}
      vom #{I18n.l start_date}
      bis #{I18n.l end_date}
    MESSAGE
  end

  delegate :name, to: :customer

  def path
    url_helpers.admin_booking_path(self)
  end

  def traveler_names
    travelers.map(&:name)
  end

  def text
    name.presence || comment
  end

  def villa_name
    villa.try :name
  end
end
