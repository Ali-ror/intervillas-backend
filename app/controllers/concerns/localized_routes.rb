module LocalizedRoutes
  extend ActiveSupport::Concern

  included do |base|
    helper LocalizedRoutes::Helper
    base.include Helper
  end

  module Helper
    extend ActiveSupport::Concern

    %i[
      villa
      villas
      villa_reviews
      villa_searches
    ].each do |resource_name|
      %i[path url].each do |type|
        define_method "#{resource_name}_#{type}" do |*args, **opts|
          public_send "#{I18n.locale}_#{resource_name}_#{type}", *args, **opts
        end
      end
    end
  end
end
