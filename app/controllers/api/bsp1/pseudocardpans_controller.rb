class Api::Bsp1::PseudocardpansController < ApiController
  skip_before_action :verify_authenticity_token

  def create
    if booking.update pseudocardpan: params.require(:pseudocardpan)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def booking
    @booking ||= Inquiry.find_by!(token: params[:inquiry_token]).reservation_or_booking
  end
end
