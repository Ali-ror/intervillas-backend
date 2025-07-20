module Digineo::I18n

  def self.included(base)
    base.send :include, i18n_methods
  end

  def self.i18n_methods
    Module.new do
      def self.included(base)
        base.translated_attribute_names.each do |translated_attribute_name|
          I18n.available_locales.each do |locale|
            define_globalized_setter(locale, translated_attribute_name)
            define_globalized_getter(locale, translated_attribute_name)
          end
        end
      end

      def self.define_globalized_setter(locale, translated_attribute_name)
        define_method "#{locale}_#{translated_attribute_name}=" do |arg|
          I18n.with_locale(locale) do
            send("#{translated_attribute_name}=", arg)
          end
        end
      end

      def self.define_globalized_getter(locale, translated_attribute_name)
        define_method "#{locale}_#{translated_attribute_name}" do
          I18n.with_locale(locale) do
            send(translated_attribute_name)
          end
        end
      end
    end
  end
end
