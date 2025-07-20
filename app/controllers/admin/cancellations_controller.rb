class Admin::CancellationsController < Admin::InquiriesController
  layout "admin_bootstrap"

  expose :cancellations do
    ::Cancellation
      .accessible_by(current_ability)
      .order(cancelled_at: :desc)
      .villa(params[:villa_id])
      .paginate(page: params[:page] || 1, per_page: 40)
  end

  expose :cancellation, before: [:show] do
    ::Cancellation.find params[:id]
  end

  expose :inquiry, before: [:show] do
    cancellation.inquiry
  end

  expose(:boat)           { boat_inquiry.try(:boat) }
  expose(:villa_inquiry)  { inquiry.villa_inquiry }

  expose(:view_adapter)     { ManagerBookingView.new cancellation, admin_cancellations_path }
  expose(:cable_form)       { CableForm.from_cable inquiry.cables.build }
  expose(:booking_messages) { view_adapter.messages }
  expose(:booking_cables)   { current_user.cables_for cancellation }

  def show
    authorize! :read, cancellation
  end

  def edit
    authorize! :edit, cancellation
  end

  def update
    authorize! :update, cancellation
    update_params = params.require(:inquiry).permit(:comment)

    if inquiry.update(update_params)
      redirect_to [:admin, cancellation], notice: "Kommentar gespeichert"
    else
      render :show
    end
  end

  private

  def set_locale
    if (locale = params[:locale].presence)
      I18n.locale = locale
    else
      super
    end
  end
end
