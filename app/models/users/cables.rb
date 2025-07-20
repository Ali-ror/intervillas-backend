module Users::Cables
  extend ActiveSupport::Concern

  included do
    has_many :cables, through: :contacts
  end

  # taucht auch auf Bunchungsseite (/bookings/:id) auf, die auch von Admins
  # eingesehen werden kann
  def cables_for(booking)
    (admin? ? Cable : cables).where(inquiry_id: booking.id)
  end

  # nur für Manager/Owner interessant
  def recent_cables
    cables.order(updated_at: :desc).limit 20
  end

end
