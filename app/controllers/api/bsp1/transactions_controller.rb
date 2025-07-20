class Api::Bsp1::TransactionsController < ApiController
  skip_before_action :verify_authenticity_token

  def create
    bsp1_process  = booking.bsp1_payment_processes.authorize(params.require(:payment_scope))
    bsp1_response = bsp1_process.response

    if bsp1_response.redirect?
      render json: { redirect: bsp1_response.redirect_url }
    elsif bsp1_response.error?
      render json: { customermessage: bsp1_response.customermessage }, status: :unprocessable_entity
    else
      render json: { bsp1_process_id: bsp1_process.id }, status: :accepted
    end
  end

  def callback
    pprocess = Bsp1PaymentProcess.find_by!(reference: Base64.urlsafe_decode64(params[:reference_base64]))
    case params[:result]
    when "success"
      pprocess.update status: "WAIT"
    when "error", "cancel"
      pprocess.update status: "ERROR"
      flash[:error] = I18n.t(safari? ? "safari" : "other", scope: "bsp1.error_please_retry")
    end

    redirect_to payments_url(token: pprocess.inquiry.token)
  end

  private

  def booking
    @booking ||= Inquiry.find_by!(token: params[:inquiry_token]).reservation_or_booking
  end

  def safari?
    /safari|applewebkit/ =~ request.user_agent.to_s.downcase
  end
end
