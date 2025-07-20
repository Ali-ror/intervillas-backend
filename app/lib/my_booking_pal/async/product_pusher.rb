module MyBookingPal
  module Async
    class ProductPusher < Base
      def perform(id, reset_progress = false)
        track_progress(id, "start", reset: reset_progress) {
          product = Product.find_by(id: id)
          return if product.blank?

          verb     = product.foreign_id? ? :put : :post
          response = MyBookingPal.send verb, "/product",
            data: product.remote_payload

          product.update!(
            foreign_id:       response.first.fetch("id"),
            skip_remote_save: true,
          )
          product
        }
      end
    end
  end
end
