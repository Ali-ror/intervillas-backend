module BoatInquiryForms
  class Base < ModelForm
    include BoatDaysCalculator
    attribute :start_date, Date
    attribute :end_date, Date

    attribute :boat_id, Integer

    delegate :inquiry_id, :inquiry,
      to: :boat_inquiry

    def boat
      @boat ||= Boat.find boat_id
    end

    def init_virtual
      self.boat_id = boat_inquiry.boat.try(:id)
    end
  end

  class ForInquiry < Base
    from_model :boat_inquiry
    attr_accessor :villa_inquiry

    delegate :villa, to: :villa_inquiry
    delegate :boat_inclusive?, to: :villa

    validates :start_date,
      presence:         true,
      starts_in_future: true,
      overlapping:      { with: :start }

    validates :end_date,
      presence:         true,
      ends_after_start: true,
      overlapping:      { with: :end },
      min_boat_length:  true,
      availability:     true

    validates :boat_id,
      # assigned_to: :villa,
      presence: true

    def filtered_attributes
      attributes.reject do |key, _value|
        key == "with_boat"
      end
    end

    def save
      model.attributes = filtered_attributes
      model.save!
    end
  end
end
