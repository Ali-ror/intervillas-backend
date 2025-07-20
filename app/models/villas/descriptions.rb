module Villas::Descriptions
  extend ActiveSupport::Concern

  included do
    attr_accessor :cached_descriptions

    has_many :descriptions do
      def get(key)
        Description.where(villa_id: proxy_association.owner.id, key: key.to_s).first
      end

      def set(key, locale, value)
        owner = proxy_association.owner
        if owner.new_record?
          owner.cached_descriptions ||= {}
          owner.cached_descriptions[key] = [value, locale]
        else
          cat = Description.find_category(key)

          I18n.with_locale(locale) do
            record = Description.where(category_id: cat.id, villa_id: owner.id, key: key).first_or_initialize
            record.text = value
            record.save!
          end
        end
      end
    end

    after_create do |record|
      record.cached_descriptions.each do |key, value|
        cat = Description.find_category(key)
        I18n.with_locale(value[1] || I18n.locale) do
          record.descriptions.create category: cat, key: key, text: value[0]
        end
      end if record.cached_descriptions
    end
  end
end
