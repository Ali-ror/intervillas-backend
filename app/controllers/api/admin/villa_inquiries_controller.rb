class Api::Admin::VillaInquiriesController < Api::Admin::InquiryBaseController
  expose(:inquiry) do
    if params[:id].present?
      Inquiry.find params[:id]
    else
      Inquiry.new(admin_submitted: true)
    end
  end

  expose(:villa_inquiry) do
    inquiry.villa_inquiry || inquiry.build_villa_inquiry
  end

  def new
    # render jbuilder template
  end

  def show
    Currency.current = villa_inquiry.inquiry.currency

    headers["Cache-Control"] = "no-store"
    render status: :ok
  end
end
