module MyBookingPal
  class LengthOfStay
    class DiffChunker
      attr_reader :product

      def initialize(product)
        @product = product
      end

      # Generates LoS data for the given date range. The data is passed to the
      # block argument in chunks with a maximum size of MAX_CHUNK_SIZE bytes.
      #
      # NOTE: This fetches the remote prices first, in order to determine the
      # changes in price rates and minimize the number (and size) of the chunks.
      #
      # @yields [String] JSON-encoded data
      # @return [void]
      def each
        updates = compute_updates
        return if updates.empty?

        prefix, suffix = %({"data":{"productId":#{product.foreign_id},"losRates":[|]}}).split("|")
        overhead       = prefix.length + suffix.length + 1 # assuming at least one comma

        # list of updates isn't empty, so start with first item
        payload = updates[0].to_json
        n       = 1

        # updates.length might be 1
        updates[1..].each do |rate|
          curr = rate.to_json

          if n > 990 || [payload, curr].sum(&:length) + overhead >= Client::MAX_CHUNK_SIZE
            # curr doesn't fit, so yield the current chunk and continue anew
            yield "#{prefix}#{payload}#{suffix}"
            payload = curr
            n       = 1
          else
            # append curr to chunk
            payload << "," << curr
            n       += 1
          end
        end

        # yield remainder, payload won't ever be empty here
        yield "#{prefix}#{payload}#{suffix}"
        nil
      end

      private

      def compute_updates
        remote  = product.remote_prices.to_set
        updates = []

        los_rates.each do |local|
          local.category = nil # remote prices wouldn't match otherwise

          updates << local unless remote.include?(local)
        end

        updates
      end

      def los_rates
        LengthOfStay.new(product).compute_rates
      end
    end
  end
end
