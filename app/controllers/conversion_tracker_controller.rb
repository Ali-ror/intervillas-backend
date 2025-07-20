class ConversionTrackerController < ApplicationController
  after_action :clear_tracking_fields

  expose(:trackable_id)   { session[:tracking_id] }
  expose(:trackable_type) { session[:tracking_type] }
  expose(:trackable)      { Inquiry.find(trackable_id) }

  expose(:inquiry)        { trackable }
  expose(:villa)          { inquiry.villa }
  expose(:boat)           { inquiry.boat }
  expose(:rentable)       { inquiry.rentable }
  expose(:resource)       { villa }

  def show
    case trackable_type
    when "inquiry"
      render template: "inquiries/create"
    when "booking"
      render :show  # soft redirect to /inquiry/token/confirmation
    else
      redirect_to root_url
    end
  end

  private

  def clear_tracking_fields
    session.delete :tracking_id
    session.delete :tracking_type
    true
  end
end
