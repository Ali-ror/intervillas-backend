require "set"

module HasRoute
  extend ActiveSupport::Concern
  mattr_accessor(:used_in) { Set.new }

  # Legt eine Route an
  def x_build_route
    # to_slug benötigt das babosa-gem
    self.route ||= build_route { |route|
      route.path = name.to_slug.approximate_ascii.normalize.to_s
    }
  end

  # entfernt die Route
  def x_destroy_route
    route&.delete
  end

  module ClassMethods
    def has_route(options = {})
      cattr_accessor :routing_controller
      self.routing_controller = options[:controller] || name.underscore.pluralize

      has_one :route,
        as:        :resource,
        dependent: :destroy
      before_create :x_build_route

      HasRoute.used_in << self
    end
  end
end
