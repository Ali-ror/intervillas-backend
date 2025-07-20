class BoatInquiriesController < ApplicationController
  expose :boats do
    boats = available_boats.to_a

    # Boot des Eigentümers nach vorne sortieren
    if (owner_boat = boats.find { |boat| boat.owner == villa.owner })
      boats.unshift boats.delete(owner_boat)
    end

    boats
  end

  expose(:inquiry)           { Inquiry.find_by!(token: params[:token]) }
  expose(:villa)             { inquiry.villa }
  expose(:boat)              { Boat.active.find(params[:boat_id]) if params[:boat_id] }
  expose(:boat_inquiry_form) { BoatInquiryForms::ForInquiry.from_boat_inquiry(boat_inquiry) }
  expose(:available_boats)   { villa.optional_boats.available_between(*max_date_range) }

  memoize(:max_date_range, private: true) do
    [inquiry.start_date + 1.day, inquiry.end_date - 1.day]
  end

  def edit
    if boats.empty?
      redirect_to new_customer_path(token: inquiry.token)
      return
    end

    boat_inquiry_form.villa_inquiry = inquiry.villa_inquiry
    boat_inquiry_form.start_date    = max_date_range[0]
    boat_inquiry_form.end_date      = max_date_range[1]
  end

  def update
    boat_inquiry_form.attributes = boat_inquiry_params

    if boat_inquiry_form.valid?
      boat_inquiry_form.save
      head :created, location: new_customer_path(token: inquiry.token)
      return
    end

    errors              = boat_inquiry_form.errors.as_json
    errors[:date_range] = [*errors.delete(:start_date), *errors.delete(:end_date)].uniq

    render :json,
      status: :unprocessable_entity,
      json:   errors
  end

  private

  def boat_inquiry_params
    params.require(:boat_inquiry).permit(%i[start_date end_date boat_id])
  end

  def boat_inquiry
    @boat_inquiry ||= if params[:token].present?
      inquiry.boat_inquiry || inquiry.prepare_boat_inquiry
    else
      BoatInquiry.new(boat: boat)
    end
  end
end
