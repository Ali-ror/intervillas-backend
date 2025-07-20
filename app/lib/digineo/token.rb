module Digineo::Token
  extend ActiveSupport::Concern

  TOKEN_LENGTH = 32

  included do
    before_create :set_token, unless: :token?
  end

  def set_token
    begin
      self.token = self.class.generate_token
    end while self.class.exists?(token: token)
  end

  module ClassMethods
    def generate_token(length=TOKEN_LENGTH)
      SecureRandom.urlsafe_base64(2*length).gsub(/\W/, '').slice(0,length)
    end
  end
end
