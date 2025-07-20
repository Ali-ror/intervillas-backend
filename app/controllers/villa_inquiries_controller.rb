class VillaInquiriesController < ApplicationController
  include BelongsToVilla

  expose(:villa_price) { villa.villa_price }

  expose :villa_inquiry do
    VillaInquiry.new { |vi| vi.villa = villa }
  end

  expose :villa_inquiry_form do
    VillaInquiryForms::ForInquiry.from_villa_inquiry(villa_inquiry)
  end

  def create
    if villa_inquiry_form.process(villa_inquiry_params)
      villa_inquiry_form.save
      location = if villa.boat_optional?
        inquiry_boat_inquiry_path(token: villa_inquiry.inquiry.token)
      else
        new_customer_path(token: villa_inquiry.inquiry.token)
      end

      head :created, location: location
      return
    end

    errors              = villa_inquiry_form.errors.as_json
    errors[:date_range] = [
      *errors.delete(:start_date),
      *errors.delete(:end_date),
    ].uniq

    render :json,
      status: :unprocessable_entity,
      json:   errors
  end

  # LEGACY: redirect users with bookmarks to the villa. Prepopulate
  # <ReservationForm/> through params.
  def new
    redirect_to villa_path(villa,
      start_date: start_date,
      end_date:   corrected_end_date,
      people:     {
        0 => params[:adults].presence,
        1 => params[:children_under_12].presence,
        2 => params[:children_under_6].presence,
      }.compact)
  rescue ActionController::ParameterMissing
    location = if params[:villa_id]
      villa_path(villa)
    elsif request.env["HTTP_REFERER"]
      :back
    else
      root_url
    end

    redirect_to location
  end

  # LEGACY: redirect users with bookmarks to the villa. Prepopulate
  # <ReservationForm/> through params.
  def edit
    inquiry = Inquiry.find_by!(token: params[:id])

    redirect_to villa_path(villa,
      start_date: inquiry.start_date,
      end_date:   inquiry.end_date,
      people:     {
        0 => inquiry.adults,
        1 => inquiry.children_under_12,
        2 => inquiry.children_under_6,
      }.compact)
  end

  private

  def villa_inquiry_params
    params.require(:villa_inquiry).permit(
      :villa_id,
      :start_date,
      :end_date,
      :adults,
      :children_under_6,
      :children_under_12,
      travelers: %i[title first_name last_name born_on],
    )
  end

  def gap
    villa.gap_after(start_date)
  end

  def corrected_end_date
    end_date > start_date + gap ? end_date : start_date + gap
  end

  def start_date
    params.require(:start).to_date
  end

  def end_date
    params.require(:end).to_date
  end
end
