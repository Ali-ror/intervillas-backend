class Api::ProgressController < ApiController
  skip_before_action :verify_authenticity_token

  def show
    process = case params[:provider]
    when "bsp1"
      booking.bsp1_payment_processes.find(params[:process_id])
    when "paypal"
      booking.inquiry.paypal_payments.find(params[:process_id])
    else
      raise "Unknown Provider: #{params[:provider]}"
    end

    render json: {
      status:   process.status,
      booking_status: booking.class.name,
    }
  end

  private

  def booking
    @booking ||= Inquiry.find_by!(token: params[:inquiry_token]).reservation_or_booking
  end
end
