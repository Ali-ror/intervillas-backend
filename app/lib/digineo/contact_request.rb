module Digineo
  class ContactRequest
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Translation

    attr_accessor :name,
      :email,
      :phone,
      :text,
      :user,
      :errors,
      :current_page,
      :villa_id

    validates_presence_of :name, :email, :text

    def initialize(params = {})
      params.each do |key, value|
        send "#{key}=", value
      end
      @errors = ActiveModel::Errors.new(self)
    end

    def new_record?
      true
    end

    def destroyed?
      true
    end

    def persisted?
      false
    end

    def self.i18n_scope
      :activerecord
    end

    def read_attribute_for_validation(attr)
      send(attr)
    end

    def villa
      return if villa_id.blank?

      @villa ||= Villa.find_by id: villa_id
    end
  end
end
