module Inquiry::Communications
  extend ActiveSupport::Concern

  included do
    has_many :messages, dependent: :destroy

    scope :not_reminded, -> { where reminded_on: nil }
  end

  def send_submission_mail
    messages.create! template: "submission_mail", recipient: customer
  end

  def to_s
    <<~MESSAGE.squish
      von #{customer.name}
      fur #{villa.name}
      vom #{I18n.l start_date}
      bis #{I18n.l end_date}
    MESSAGE
  end

  def remind!
    # Mehrfaches Erinnern am selben Tag verhindern
    return false if reminded_on == Date.current

    messages.create!(template: "reminder_mail", recipient: customer) if still_available?
    update reminded_on: Date.current
  end
end
