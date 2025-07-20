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
    class Cancel < Base
      self.success_response = "Booking reservation was cancelled successfully"

      def manage_booking!
        assign_inquiry_by_reservation_id!
        inquiry.cancel!(reason: "Cancelled via BookingPal")
      end
    end
  end
end
