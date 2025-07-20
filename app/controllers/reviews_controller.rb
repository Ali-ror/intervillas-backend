class ReviewsController < InheritedResources::Base
  include ActionView::RecordIdentifier

  actions :show, :edit, :update, :index

  belongs_to :villa, optional: true

  helper_method :villa

  def index
    respond_to do |format|
      format.html do
        render :index, status: response_status
      end
      format.json
    end
  end

  def show
    if villa.active
      redirect_to villa_reviews_path(villa, anchor: dom_id(resource)), status: :moved_permanently
      return
    end

    redirect_to villa_url(villa)
  rescue ActiveRecord::RecordNotFound
    redirect_to villa_url(villa)
  end

  def update
    update! { villa_url(parent) }
  end

  # wie `update`, aber ohne Persistenz
  def preview
    resource.assign_attributes review_params
    render partial: "reviews/review", layout: false
  end

  def redirect_unlocalized
    redirect_to villa_reviews_path(villa), status: :moved_permanently
  end

  private

  def response_status
    return :ok if villa.blank?

    villa.active ? :ok : :gone
  end

  alias villa parent

  def review_params
    params.require(:review).permit(:city, :text, :name, :rating)
  end

  def resource_collection_name
    %w[edit preview update].include?(action_name) ? :unpublished_reviews : super
  end

  def collection
    @reviews ||= super.undeleted.published
      .includes(villa: %i[main_image route], inquiry: :villa_inquiry)
      .order(id: :desc)
      .paginate(page: params[:page] || 1)
  end

  def resource
    @review ||= if action_name == "show"
      end_of_association_chain.find params[:id]
    else
      end_of_association_chain.find_by_token! params[:id]
    end
  end
end
