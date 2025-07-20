module MyBookingPal
  module Async
    # Pushes product data (i.e. Villa) onto the MyBookingPal servers.
    class ProductUpdater < Base
      attr_reader :product

      delegate :id, :villa, :foreign_id?,
        to: :product

      delegate :url_helpers,
        to: "Rails.application.routes"

      # See #perform for parameters.
      def self.perform_async(id, step, *)
        UpdateProgress.start!(id, step)
        super
      end

      # @param [Integer] id
      #   ID of Villa to update/create Product for.
      # @param ["start" | "images" | "fees_taxes" | "los_prices"] step
      #   Name of step to execute.
      # @param [Hash{String, *}] opts
      #   Extra options, used for some steps.
      # @option opts [String] :chunk
      #   A JSON-encoded LoS price chunk.
      def perform(id, step, opts = {})
        @product  = Product.find_or_initialize_by(id: id)
        @chunk    = opts["chunk"]

        if step != "start" && !foreign_id?
          # cleanup: product was removed after start step
          UpdateProgress.new(id).destroy!
          return
        end

        send "push_#{step}!"
      end

      private

      # Creates or updates product record on MyBookingPal and schedules
      # additional jobs for LOS prices, images, etc.
      def push_start!
        ProductPusher.new.perform(id)

        # fan out next steps
        %w[images fees_taxes los_prices].each do |step|
          self.class.perform_async(id, step)
        end
      end

      # On first invocation, this fetches the prices stored on MyBookingPal
      # and compares them to the prices generated locally. The difference
      # is then scheduled to be updated (in one or more additional jobs).
      def push_los_prices!
        if @chunk.present?
          LosPricesPusher.new.perform(id, @chunk)
          return
        end

        track_progress(id, "los_prices") {
          LengthOfStay::DiffChunker.new(product).each do |chunk|
            self.class.perform_async(id, "los_prices", { "chunk" => chunk })
          end
        }
      end

      def push_images!
        ImagesPusher.new.perform(id)
      end

      def push_fees_taxes!
        FeesTaxesPusher.new.perform(id)
      end
    end
  end
end
