class AdminController < InheritedResources::Base
  include Admin::ControllerExtensions
  include Digineo::Pagination

  layout :choose_layout

  private

  def choose_layout
    request.xhr? ? false : "application"
  end
end
