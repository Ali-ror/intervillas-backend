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
    class Create < Base
      self.success_response = "Booking reservation was created successfully"

      Invalid      = Class.new StandardError
      NotAvailable = Class.new StandardError

      def manage_booking!
        self.inquiry = Inquiry.create!(
          external:                  true,
          comment:                   [payload.comment_for_inquiry, payload.notes].compact_blank.join("\n\n"),
          currency:                  Currency::USD,
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
    end
  end
end
