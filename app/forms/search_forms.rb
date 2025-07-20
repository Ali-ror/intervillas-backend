module SearchForms
  class Base < ModelForm
    class_attribute :route_identifier

    def self.model_name
      ActiveModel::Name.new self.class, nil, route_identifier
    end

    def persisted?
      false
    end

    def self.from_params(user, params)
      params ||= {}

      new.tap { |form|
        form.user = user if form.respond_to?(:user=)
        form.attributes.each do |k, _|
          form[k] = params[k] if params.key?(k)
        end
      }
    end
  end

  class Customer < Base
    attr_accessor :user

    self.route_identifier = "CustomerSearch"

    attribute :query, String
    validates :query,
      presence: true,
      length:   { minimum: 3 }

    attribute :villa_id, Integer
    attribute :boat_id,  Integer

    delegate :boats, :villas,
      to: :user

    def rentables(which)
      (which == :villas ? villas : boats).map { |r|
        [r.admin_display_name, r.id]
      }
    end

    def query=(val)
      super val.to_s.strip.downcase
    end

    def perform!
      Search.customer(user, **attributes)
    end
  end

  class Review < Base
    self.route_identifier = "Review"

    attribute :villa_id,   Integer
    attribute :inquiry_id, Integer

    attribute :filter, String
    validates :filter,
      inclusion: { in: Search::Review::FILTER }

    def perform!
      Search.review(**attributes)
    end
  end
end
