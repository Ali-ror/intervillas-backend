module MyBookingPal
  Error        = Class.new StandardError
  TokenMissing = Class.new Error
  APIError     = Class.new Error
  RateLimited  = Class.new Error

  class << self
    delegate :get, :delete, :post, :put,
      to: :client

    def client
      @client ||= Client.new
    end

    def product(id)
      case id
      when :first, :last
        Product.send(id)
      when Integer
        Product.find(id)
      when Hash
        Product.find_by(id)
      end
    end
  end
end
