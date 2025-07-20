module MiscForms
  class Inquiry < ModelForm
    from_model :inquiry

    attribute :comment, String
  end

  class Booking < ModelForm
    from_model :booking

    delegate :inquiry, to: :booking

    attribute :comment, String

    attribute :summary_month, Integer
    validates :summary_month,
      numericality: { only_integer: true },
      inclusion:    { in: (1..12).to_a },
      allow_nil:    true

    attribute :summary_year, Integer
    validates :summary_year,
      numericality: { only_integer: true, greater_than_or_equal_to: 2011 },
      allow_nil:    true

    def init_virtual
      self.comment = inquiry.comment if persisted?

      if booking.summary_on?
        self.summary_month = booking.summary_on.month
        self.summary_year  = booking.summary_on.year
      end
    end

    def save
      ::Booking.transaction do
        inquiry.comment = comment
        inquiry.save!

        set_summary_on!
        booking.save!
      end
    end

    private

    def set_summary_on!
      return unless summary_year && summary_month

      booking.summary_on = Time.utc(summary_year, summary_month)
    rescue TypeError
      # ignore
    end
  end
end
