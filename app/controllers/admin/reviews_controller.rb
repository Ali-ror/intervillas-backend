class Admin::ReviewsController < ApplicationController
  include Admin::ControllerExtensions

  layout "admin_bootstrap"
  load_and_authorize_resource :booking

  before_action :check_admin!

  expose :review_filter_form do
    pparams = params.permit(review: %i[villa_id inquiry_id filter])
    SearchForms::Review.from_params current_user, pparams[:review]
  end

  expose :reviews do
    r = review_filter_form.perform!
    r.paginate(per_page: 40, page: params.fetch(:page, 1))
  end

  expose :review do
    Review.find params[:id]
  end

  expose :review_form do
    ReviewForms::Admin.from_review review
  end

  def create
    form = ReviewForms::Create.from_params params.require(:review).permit(:inquiry_id, :deliver_review_mail)
    if form.valid?
      form.save
      flash[:success] = t(".success")
    else
      flash[:error] = t(".failure")
    end

    redirect_to edit_admin_booking_path(form.inquiry_id, anchor: "review")
  end

  def update
    review_form.attributes = review_params

    unless review_form.valid?
      flash[:error] = t(".failure")
      render :edit
      return
    end

    review_form.save
    flash[:success] = t(".success")
    redirect_to params[:return_to] || admin_reviews_url
  end

  def toggle_archive
    ReviewForms::ToggleArchive.from_review(review).save
    render json: { active: review.deleted_at? }
  end

  def toggle_publish
    ReviewForms::TogglePublish.from_review(review).save
    render json: { active: review.published_at? }
  end

  private

  def review_params
    params.require(:review).permit(:text, :name, :city, :rating, :published, :archived)
  end
end
