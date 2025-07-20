# == Schema Information
#
# Table name: booking_pal_reservations
#
#  id             :bigint           not null, primary key
#  payload        :jsonb            not null
#  type           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  blocking_id    :bigint
#  inquiry_id     :bigint
#  reservation_id :string
#  villa_id       :bigint           not null
#
# Indexes
#
#  index_booking_pal_reservations_on_blocking_id  (blocking_id)
#  index_booking_pal_reservations_on_inquiry_id   (inquiry_id)
#  index_booking_pal_reservations_on_villa_id     (villa_id)
#
# Foreign Keys
#
#  fk_rails_...  (blocking_id => blockings.id) ON DELETE => nullify
#  fk_rails_...  (inquiry_id => inquiries.id) ON DELETE => restrict
#  fk_rails_...  (villa_id => villas.id) ON DELETE => cascade
#
module MyBookingPal
  module Reservation
    class Base < ApplicationRecord
      self.table_name = "booking_pal_reservations"

      class_attribute :success_response,
        instance_writer: false

      belongs_to :product,
        optional:    true,
        class_name:  "MyBookingPal::Product",
        foreign_key: :villa_id,
        inverse_of:  :reservations

      belongs_to :villa

      belongs_to :inquiry,
        optional: true

      before_create :manage_booking!

      def self.create_from_payload!(payload)
        new(payload:).tap { |res|
          res.reservation_id = res.payload.reservation_id
          res.product        = Product.find_by!(foreign_id: res.payload.product_id)
          res.villa          = res.product.villa
          res.save!
        }
      end

      def manage_booking!
        raise NotImplementedError, "must be implemented in subclass"
      end

      def payload
        Payload.new(super)
      end

      def payload=(val)
        val = val.as_json if val.is_a?(Payload) # extract raw payload data
        super
        payload
      end

      # used in Update and Cancel sub-classes
      def assign_inquiry_by_reservation_id!
        self.inquiry_id ||= Create.find_by!(
          reservation_id: payload.reservation_id,
        ).inquiry_id
      end
    end
  end
end
