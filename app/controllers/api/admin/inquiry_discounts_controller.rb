class Api::Admin::InquiryDiscountsController < ApplicationController
  include Admin::ControllerExtensions
  include Api::Admin::Common

  def update
    return head :ok if discount_params[:value].to_d.zero? && discount.destroy
    return head :ok if discount.update(discount_params)

    render :json,
      json:   { errors: discount.errors },
      status: :unprocessable_entity
  end

  private

  def discount_params
    params.require(:discount).permit :value, period: []
  end

  def inquiry
    @inquiry ||= Inquiry.find(params[:inquiry_id])
  end

  def discount
    @discount ||= inquiry.discounts.find_or_initialize_by \
      inquiry_kind: params[:kind],
      subject:      params[:subject]
  end
end
