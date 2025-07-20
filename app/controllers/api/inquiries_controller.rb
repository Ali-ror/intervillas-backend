class Api::InquiriesController < ApplicationController
  expose(:inquiry) { Inquiry.find_by!(token: params[:token]) }

  def show
    respond_to do |format|
      format.json do
        render partial: "/api/clearings/clearing", locals: { clearing: inquiry.clearing }
      end
    end
  end
end
