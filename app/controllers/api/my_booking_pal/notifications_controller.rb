module Api
  module MyBookingPal
    class NotificationsController < ApplicationController
      skip_forgery_protection
      wrap_parameters false

      # POST /api/my_booking_pal/notifications
      #
      # See https://developerstesting.channelconnector.com/documentation\
      # #/rest/api-endpoints/asynchronous-push-messages/validation-push-asynchronous-message
      # and https://developerstesting.channelconnector.com/documentation\
      # #/rest/api-endpoints/asynchronous-push-messages/product-image-push-asynchronous-message
      #
      # NOTE: Their docs imply that the requests are sent to `<endpoint>/push` and
      # `<endpoint>/pushImage` (where <endpoint> is confugurable, see Client#info=),
      # however this is not true, both are sent to `<endpoint>`.
      def create
        case params[:type]
        when "BP_VALIDATION"
          process_product_validation params.fetch(:validation)
          head :ok
        when "PROCESSING_IMAGES"
          process_images_import params.fetch(:processingImage)
          head :ok
        when "PROCESSED_LOS", "PROCESSED_FEES_AND_TAXES"
          # XXX: this is undocumented, we'll just ignore it for now
          head :ok
        else
          Sentry.capture_message "unexpected notification type",
            extra: { type: params[:type] }
          head :not_found
        end
      end

      private

      def process_product_validation(values)
        values.each do |v|
          pro = ::MyBookingPal::Product.find_by foreign_id: v[:productId]
          next unless pro

          pro.update(
            status:           (v[:isValid] ? :valid : :inactive),
            status_message:   v[:validationErrors].presence,
            skip_remote_save: true,
          )
        end
      end

      def process_images_import(values)
        values.each do |v|
          id, images = v.values_at(:productId, :images)
          pro        = ::MyBookingPal::Product.find_by(foreign_id: id)
          next unless pro

          # process deletes first!
          deletes, imports = images
            .map { ::MyBookingPal::ImageImport::Item.from_notification(_1) }
            .compact
            .partition { _1.type == "DELETE" }

          # XXX: These produce a lot of DELETE, UPDATE and INSERT queries, which
          # should be optimized at some point. Since this is an API controller
          # and we expect at most ~100 image notifications in a single request,
          # the overhead is manageable.
          deletes.each            { |item|    item.delete!(pro.image_imports) }
          imports.each_with_index { |item, i| item.import!(pro.image_imports, i + 1) }
        end
      end
    end
  end
end
