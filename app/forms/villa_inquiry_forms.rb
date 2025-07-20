module VillaInquiryForms
  class ForInquiry < ModelForm
    from_model :villa_inquiry

    include NightsCalculator

    delegate :inquiry_id, :inquiry,
      to: :villa_inquiry

    delegate :booked?, :booking,
      to:        :inquiry,
      allow_nil: true

    # def booking_travelers
    delegate :travelers,
      to:     :booking,
      prefix: true

    attribute :adults, Numeric
    validates :adults,
      presence:     true,
      numericality: {
        only_integer:             true,
        greater_than_or_equal_to: 2,
      }

    %i[children_under_6 children_under_12].each do |prop|
      attribute prop, Numeric
      validates prop,
        numericality: {
          only_integer:             true,
          greater_than_or_equal_to: 0,
          allow_nil:                true,
          allow_blank:              true,
        }
    end

    attribute :villa_id

    attribute :start_date, Date
    validates :start_date,
      presence:         true,
      starts_in_future: { in: 2.days }

    attribute :end_date, Date
    validates :end_date,
      presence:         true,
      ends_after_start: true,
      availability:     true,
      minimum_length:   true

    attr_accessor :villa

    def init_virtual
      self.villa = villa_inquiry.villa
    end

    def save
      inquiry = villa_inquiry.inquiry ||= Inquiry.create!(currency: Currency.current)

      VillaInquiry.transaction do
        if marked_for_destruction?
          model.destroy if persisted?
        else
          model.attributes = attributes.except(:travelers)
          model.save
        end
      end

      return unless villa.boat_inclusive?

      inquiry.prepare_boat_inquiry
      inquiry.boat_inquiry.save!
    end
  end
end
