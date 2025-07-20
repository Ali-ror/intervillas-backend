module Interboats
  extend ActiveSupport::Concern

  BOATS_DOMAIN = 'interboats-florida'

  included do
    before_action :switch_view_paths
  end

  def switch_view_paths
    return unless request.domain.include? BOATS_DOMAIN
    prepend_view_path Rails.root.join('app/boat_views')
  end
end
