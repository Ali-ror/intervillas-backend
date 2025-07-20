module DigineoExposer
  VERSION = "0.2.5".freeze

  module Memoizable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def memoize(method_name, options={}, &block) # rubocop:disable Metrics
        # defaults
        options[:nil]     = true  unless options.key?(:nil)
        options[:private] = false unless options.key?(:private)

        m     = method_name.to_sym
        ivar  = "@#{method_name}".to_sym

        if options[:nil] == true
          define_method m do |reload=false|
            remove_instance_variable(ivar) if reload
            if instance_variable_defined?(ivar)
              instance_variable_get(ivar)
            else
              instance_variable_set(ivar, instance_eval(&block))
            end
          end
        else
          define_method m do |reload=false|
            remove_instance_variable(ivar) if reload
            instance_variable_get(ivar) || instance_variable_set(ivar, instance_eval(&block))
          end
        end

        private(m) if options[:private] == true
        m
      end
    end
  end

  module Exposer
    def self.included(base)
      base.send :include, DigineoExposer::Memoizable
      base.extend ClassMethods
    end

    module ClassMethods
      def expose(method_name, options={}, &block)
        memoize method_name, private: true, nil: options.fetch(:nil, false), &block
        helper_method method_name
        before_action method_name, only: options[:before] if options.key?(:before)
      end
    end
  end

  def self.setup!
  end
end

msg = "Found global %0$s:%1$s, will not set to DigineoExposer::%0$s"

defined?(::Exposer) \
  ? $stderr.puts(msg % ["Exposer", ::Exposer.class.to_s])
  : ::Exposer = DigineoExposer::Exposer

defined?(::Memoizable) \
  ? $stderr.puts(msg % ["Memoizable", ::Memoizable.class.to_s])
  : ::Memoizable = DigineoExposer::Memoizable
