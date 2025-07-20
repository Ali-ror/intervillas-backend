module MyBookingPal
  module Async
    # Removes a product from the MyBookingPal servers.
    #
    # Our product record is already gone at the time of #perform.
    class ProductDeleter < Base
      def perform(foreign_id)
        MyBookingPal.delete("/product/#{foreign_id}")
      end
    end
  end
end
