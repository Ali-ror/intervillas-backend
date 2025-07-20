require "graticule"

module ActiveSupport
  module Callbacks
    module ClassMethods
      # Runs the given block without invoking the given callbacks.
      #
      # XXX: This should be used *solely* by the ActsAsGeocodable
      # concern (until it has been refactored).
      def without_callback(*args)
        skip_callback(*args)
        yield
        set_callback(*args)
      end
    end
  end
end
