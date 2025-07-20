class Api::Admin::ReviewsController < ApplicationController
  include Admin::ControllerExtensions
  before_action :check_admin!

  expose(:reviews) do
    scope = Review.undeleted
      .includes(inquiry: %i[villa_inquiry boat_inquiry])
      .order(inquiry_id: :desc)
    scope = scope.where(villa_id: params[:villa_id]) if params.key?(:villa_id)
    scope
  end

  expose(:review) do
    reviews.find(params[:id])
  end

  def index
    # render api/admin/reviews/index.json.builder
  end

  def update
    permitted_params = params.require(:review).permit(:rating, :name, :city, :text, :published_at)
    review.update permitted_params
    # render api/admin/reviews/update.json.builder
  end

  def destroy
    review.update deleted_at: Time.current
    head :ok
  end
end
