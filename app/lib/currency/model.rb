module Currency::Model # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  class_methods do
    def currency_values(*attributes, **opts)
      attributes.each do |a|
        define_method a do
          var = super() # rubymine dreht ab, wenn geinlinet
          return var if var.nil? || var.is_a?(Currency::Value)

          Currency::Value.new(var, opts[:currency] || inquiry.currency)
        end
      end
    end

    def convert_currency_values(*attributes)
      attributes.each do |a|
        define_method a do
          var = super()
          return var if var.nil?

          Currency::Value.new(var, "EUR").convert(Currency.current)
        end
      end
    end
  end
end
