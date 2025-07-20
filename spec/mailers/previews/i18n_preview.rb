module I18nPreview
  def self.included(base)
    base.class_eval do
      public_instance_methods(false).each do |action|
        private action

        %i[de en].each do |locale|
          define_method [action, locale].join("_") do
            I18n.with_locale(locale) do
              params[:action] = action
              send action
            end
          end
        end
      end
    end
  end
end
