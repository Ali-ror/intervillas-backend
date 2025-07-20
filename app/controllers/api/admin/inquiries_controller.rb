class Api::Admin::InquiriesController < Api::Admin::InquiryBaseController
  include Api::Admin::Common

  expose(:inquiry)       { Inquiry.find(params[:id]) }
  expose(:villa_inquiry) { inquiry.villa_inquiry }

  def index
    render json: inquiries + blockings
  end

  def create
    @inquiry = Inquiry.new_from_controller(inquiry_params)
    if @inquiry.save
      render :json,
        json:   { url: edit_admin_inquiry_path(@inquiry) },
        status: :created
    else
      logger.error { @inquiry.errors.inspect }
      render :json,
        json:   { errors: @inquiry.errors },
        status: :ok
    end
  end

  def update
    if params["inquiry"]["boat_inquiry_attributes"].present?
      params["inquiry"]["boat_inquiry_attributes"]["skip_clearing_items"] = true
    end

    if inquiry.update(inquiry_params)
      inquiry.reload
      inquiry.clearing(reload: true)

      render "/api/admin/villa_inquiries/show"
    else
      render :json,
        status: :unprocessable_entity,
        json:   inquiry.errors
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit :currency, :external,
      travelers_attributes:      %i[
        id first_name last_name price_category born_on start_date end_date _destroy
      ],
      villa_inquiry_attributes:  %i[
        inquiry_id
        villa_id
        start_date
        end_date
        skip_clearing_items
        skip_notification
        energy_cost_calculation
      ],
      clearing_items_attributes: [
        :id, :villa_id,
        :boat_id,
        :inquiry_id,
        :category,
        :minimum_people,
        :amount,
        :start_date,
        :end_date,
        :_destroy,
        :note,
        :normal_price,
        { price: %i[value currency] },
      ],
      boat_inquiry_attributes:   %i[
        inquiry_id
        boat_id
        start_date
        end_date
        skip_clearing_items
        skip_notification
        _destroy
      ],
      customer_attributes:       %i[
        email phone locale currency title first_name last_name
      ]
  end

  def inquiries
    select(Inquiry.complete)
  end
end
