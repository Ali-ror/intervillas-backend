module MyBookingPal
  module Async
    class ImagesPusher < Base
      delegate :url_helpers,
        to: "Rails.application.routes"

      def perform(id, reset_progress = false)
        track_progress(id, "images", reset: reset_progress) {
          product = Product.find_by(id: id)
          return unless product&.foreign_id?

          active_images = product.villa.images.active.to_a
          images        = active_images.map { as_image_payload(_1) }

          MyBookingPal.put("/image", data: {
            productId: product.foreign_id,
            images:    images,
          })

          remember_pending_imports(product, active_images)
        }
      end

      private

      def as_image_payload(img)
        {
          url:  url_helpers.media_url(img, preset: :mybookingpal, name: "iv#{img.id}.jpg"),
          tags: img.amenity_ids,
        }.compact_blank
      end

      def remember_pending_imports(product, active_images)
        now = Time.current
        active_images.each do |img|
          product.image_imports.find_or_initialize_by(medium_id: img.id).update(
            status:     :pending,
            created_at: now,
            updated_at: now,
          )
        end

        product.image_imports
          .where.not(medium_id: active_images.map(&:id))
          .destroy_all
        nil
      end
    end
  end
end
