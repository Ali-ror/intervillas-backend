module MyBookingPal
  module Async
    class LosPricesPusher < Base
      def perform(id, chunk = nil, reset_progress = false)
        if chunk.nil?
          product = Product.find(id)

          LengthOfStay::DiffChunker.new(product).each do |chunk|
            self.class.perform_async(id, chunk, true)
          end

          return
        end

        track_progress(id, "los_prices", reset: reset_progress) {
          # use body for chunks, not data
          MyBookingPal.post("/losrates", body: chunk)
        }
      end
    end
  end
end
