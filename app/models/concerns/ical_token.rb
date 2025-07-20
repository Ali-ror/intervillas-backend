module IcalToken
  extend ActiveSupport::Concern

  included do
    before_save :generate_ical_token, unless: :ical_token?
  end

  def generate_ical_token
    begin
      self.ical_token = SecureRandom.urlsafe_base64(32)
    end while self.class.exists?(ical_token: ical_token)
  end

  def regenerate_ical_token!
    self.ical_token = nil
    save!
  end
end
