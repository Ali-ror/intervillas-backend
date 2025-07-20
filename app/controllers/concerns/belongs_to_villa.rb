module BelongsToVilla
  extend ActiveSupport::Concern

  included do
    helper_method :villa
  end

  private

  def villa
    @villa ||= Villa.find(params[:villa_id])
  end
end
