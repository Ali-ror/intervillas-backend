# == Schema Information
#
# Table name: booking_pal_image_imports
#
#  id         :bigint           not null, primary key
#  position   :integer
#  status     :integer          default("pending"), not null
#  version    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  medium_id  :bigint           not null
#  product_id :bigint           not null
#
# Indexes
#
#  index_booking_pal_image_imports_on_medium_id          (medium_id)
#  index_booking_pal_image_imports_on_product_and_image  (product_id,medium_id) UNIQUE
#  index_booking_pal_image_imports_on_product_id         (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (medium_id => media.id) ON DELETE => cascade
#  fk_rails_...  (product_id => booking_pal_products.id) ON DELETE => cascade
#
module MyBookingPal
  class ImageImport < ApplicationRecord
    self.table_name = "booking_pal_image_imports"

    belongs_to :medium
    belongs_to :product,
      class_name: "MyBookingPal::Product"

    enum :status, {
      pending: 0,
      success: 1,
      failure: 2,
      deleted: 3,
    }, prefix: true

    Item = Struct.new(:type, :success, :medium_id, :version, :position, keyword_init: true) do
      def self.from_notification(data)
        url = data["url"]
        return if url.blank?

        medium_id = extract_medium_id(data["url"])
        return unless medium_id

        new(
          type:      data["type"],
          success:   data["success"],
          medium_id:,
          version:   data["version"],
        )
      end

      def self.from_remote(list)
        list.sort_by { _1["sort"].to_i }.map { |data|
          medium_id = extract_medium_id(data["url"])
          next unless medium_id

          new(
            type:      "IMPORT",
            success:   true,
            medium_id:,
            version:   "unknown",
          )
        }.compact
      end

      def self.extract_medium_id(url)
        return if url.blank?

        medium_id = url[%r{/iv(\d+).jpg\z}, 1]&.to_i
        return if     medium_id.blank?
        return unless Media::Image.exists?(id: medium_id)

        medium_id
      end

      def import!(scope, position)
        scope.find_or_initialize_by(medium_id:).update(
          status:   (success ? :success : :failure),
          version:,
          position:,
        )
      end

      def delete!(scope)
        scope.find_or_initialize_by(medium_id:).update(
          status: :deleted,
        )
      end
    end
  end
end
