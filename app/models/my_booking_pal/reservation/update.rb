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
    class Update < Base
      self.success_response = "Booking reservation was updated successfully"

      def manage_booking!
        assign_inquiry_by_reservation_id!
        inquiry.update!(
          comment:                   amended_comment,
          customer_attributes:       payload.to_customer_params,
          travelers_attributes:      payload.to_traveler_params,
          skip_sync_traveler_dates:  true,
          clearing_items_attributes: payload.to_clearing_item_params(villa),
          villa_inquiry_attributes:  {
            villa_id:,
            start_date:              payload.start_date,
            end_date:                payload.end_date,
            adults:                  payload.adults,
            children_under_12:       payload.children,
            skip_clearing_items:     true,
            skip_discounts:          true,
            energy_cost_calculation: "override_included",
          },
        )
      end

      private

      def amended_comment
        comment             = +inquiry.comment.to_s # XXX: nil.to_s.frozen? == true
        amend_comment       = [
          payload.comment_for_inquiry.presence,
          payload.notes.presence,
        ].compact_blank.reject { comment.include?(_1) }

        if amend_comment
          now = Time.current.strftime("%Y/%m/%d %H:%M")
          comment << "\n\nUpdate #{now}:\n" << amend_comment.join("\n\n")
        end

        comment
      end
    end
  end
end
