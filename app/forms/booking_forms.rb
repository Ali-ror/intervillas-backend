module BookingForms
  class Customer < ModelForm
    attr_accessor :inquiry, :user

    attribute :customer, CustomerForms::ForBooking

    attribute :travelers, Array[TravelerForm]

    attribute :agb, Axiom::Types::Boolean
    validates :agb,
      acceptance: { accept: true }

    delegate :attributes=,
      to:     :customer,
      prefix: true

    def travelers_attributes=(params)
      travelers.each.with_index do |traveler_form, index|
        traveler_form.attributes = params[index.to_s]
      end
    end

    def any_travelers?
      travelers.any?
    end

    def self.model_name
      Booking.model_name
    end

    # @param [Inquiry] inquiry
    # @param [User, NilClass] user Benutzer, der die Buchung durchführt.
    #   Admin-Nutzer setzen 2 Tage Vorlaufprüfung und Reservierung ausser Kraft.
    # @return BookingForms::Customer
    def self.from_inquiry(inquiry, user = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      form          = new
      villa_inquiry = inquiry.villa_inquiry

      if villa_inquiry.travelers.present?
        villa_inquiry.travelers.order(price_category: :asc).each do |traveler|
          form.travelers << TravelerForm.from_traveler(traveler)
        end
      end

      form.customer = CustomerForms::ForBooking.new
      form.user     = user

      if (customer = inquiry.customer)
        form.customer.attributes = customer.attributes.slice(*form.customer.attributes.keys.map(&:to_s))
        form.customer.first_name = customer.first_name
        form.customer.last_name  = customer.last_name

        if form.travelers.any? && form.travelers.first.first_name.blank? && form.travelers.first.last_name.blank?
          form.travelers.first.first_name = customer.first_name
          form.travelers.first.last_name  = customer.last_name
        end
      end

      form.inquiry = inquiry
      form
    end

    def valid?
      [ # && evaluiert lazy, wir wollen aber alle Fehlermeldungen
        (customer.present? ? customer.valid? : true),
        travelers.map(&:valid?).all?,
        inquiry.still_available?,
        !inquiry.reserved?,
        (user&.admin? || inquiry.timely?),
        super,
      ].all?
    end

    def save
      # Customer updaten
      customer_model.update! customer.attributes

      # Booking oder Reservation (je nach Währung) erstellen
      booking = inquiry.build_booking_or_reservation(user)

      # weitere Reisende
      travelers = self.travelers.map { |traveler_form|
        Traveler.find(traveler_form.id).tap { |traveler|
          traveler.attributes = traveler_form.attributes.merge(inquiry: inquiry)
        }
      }

      Booking.transaction do
        booking.save!
        travelers.each(&:save)
      end

      begin
        booking.trigger_messages
      rescue StandardError
        # ignore
      end
    end

    private

    def customer_model
      inquiry.customer
    end
  end

  class PaymentAcknowledge < ModelForm
    from_model :booking # or cancellation
    attribute :ack_downpayment, Axiom::Types::Boolean

    def self.from(obj)
      inquiry = case obj
      when Payment::View, Booking, Cancellation, VillaInquiry, BoatInquiry
        obj.inquiry
      when Integer
        Inquiry.find obj
      when Inquiry
        obj
      else
        raise TypeError, "#{obj.class} can't be coerced into Inqiury"
      end

      from_booking inquiry.terminus
    end
  end
end
