module ReviewForms
  class Admin < ModelForm
    from_model :review

    attribute :text, String
    validates :text,
      presence: true

    attribute :name, String
    attribute :city, String

    attribute :rating, Integer
    validates :rating,
      presence:     true,
      numericality: {
        greater_than_or_equal_to: Review::RATING_RANGE.begin,
        less_than_or_equal_to:    Review::RATING_RANGE.end,
      }

    attribute :published, Axiom::Types::Boolean
    attribute :archived, Axiom::Types::Boolean

    def init_virtual
      self.published = !!review.published_at?
      self.archived = !!review.deleted_at?
    end

    def save
      review.attributes = attributes.except(:published, :archived)
      review.villa_id   = review.booking.villa.id

      if published
        review.published_at ||= Date.current
      else
        review.published_at = nil
      end

      if archived
        review.deleted_at ||= Date.current
      else
        review.deleted_at = nil
      end

      review.save!
    end
  end

  class TogglePublish < ModelForm
    from_model :review

    def save
      date = model.published_at? ? nil : DateTime.current
      model.update! published_at: date
    end
  end

  class ToggleArchive < ModelForm
    from_model :review

    def save
      date = model.deleted_at? ? nil : DateTime.current
      model.update! deleted_at: date
    end
  end

  class Create < ModelForm
    def self.model_name
      Review.model_name
    end

    def self.from_params(params = {})
      new.tap { |form|
        form.inquiry_id           = params[:inquiry_id]
        form.deliver_review_mail  = params[:deliver_review_mail]
      }
    end

    def initialize
      super
      @review = Review.new
    end

    attr_accessor :review
    delegate :id, :to_param, :persisted?, :new_record?,
      to:        :review,
      allow_nil: true

    attribute :inquiry_id, Integer
    validates :inquiry_id,
      presence: true

    attribute :deliver_review_mail, Axiom::Types::Boolean,
      default: false

    def save
      review.inquiry_id = inquiry_id
      booking           = review.booking
      review.villa_id   = booking.villa.id
      review.name       = booking.customer.last_name
      review.city       = booking.customer.city
      review.save!
      review.deliver_review_mail if deliver_review_mail
      true
    end
  end
end
