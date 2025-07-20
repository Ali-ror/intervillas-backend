module Inquiry::Billings
  extend ActiveSupport::Concern

  included do
    has_many :boat_billings,  -> { includes(rentable: :owner) },
      inverse_of: :inquiry

    has_many :villa_billings, -> { includes(rentable: :owner) },
      inverse_of: :inquiry

    # eine Abrechnung darf nur dann im Index erscheinen, wenn die Buchung
    # existiert, oder die Buchung storniert wurde
    scope :with_bookings_or_cancellations, -> {
      joins("left outer join bookings on bookings.inquiry_id = inquiries.id")
        .joins("left outer join cancellations on cancellations.inquiry_id = inquiries.id")
        .where("bookings.inquiry_id is not null or cancellations.inquiry_id is not null")
    }

    # Eine Buchung ist abrechenbar, wenn das Abreisedatum < "heute" ist.
    # Im System liegen noch ein paar tausend Buchungen, die nicht mit dem
    # System abgerechnet wurden. Wir ignorieren daher alles, was mehr als
    # 6 Monate zurückliegt.
    scope :invoicable, -> {
      includes(:villa, :boat, :customer)
        .joins("left outer join bookings on bookings.inquiry_id = inquiries.id")
        .where.not(bookings: { inquiry_id: nil })
        .joins("inner join inquiry_union_view iuv on iuv.inquiry_id = inquiries.id")
        .where("iuv.rentable_type = ? and iuv.end_date > ? and iuv.end_date < ?",
          "Villa", 6.months.ago.to_date, Date.current)
        .where.not(inquiries: { id: VillaBilling.distinct.select(:inquiry_id) })
        .order(Arel.sql("iuv.end_date asc"))
    }

    # abgerechnete Buchungen eines bestimmten Monats
    scope :cleared_for, ->(date) {
      includes(
        :customer,
        :booking,
        :cancellation,
        boat_inquiry:  %i[boat billing],
        villa_inquiry: %i[villa billing],
      ).where bookings: {
        summary_on: date.beginning_of_month.to_date,
      }
    }
  end

  def billings
    @billings ||= [*villa_billings, *boat_billings].compact
  end

  def to_billing
    @billing ||= if cancelled?
      ::Billing.new cancellation
    else
      ::Billing.new booking
    end
  end
end
