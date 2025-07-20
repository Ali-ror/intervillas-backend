class Admin::Bsp1PaymentProcessesController < ApplicationController
  include Admin::ControllerExtensions

  layout "admin_bootstrap"
  before_action :check_admin!

  expose :payment_processes do
    Bsp1PaymentProcess
      .order(id: :desc)
      .paginate(per_page: 20, page: (params[:page] || 1))
  end

  expose :payment_process do
    Bsp1PaymentProcess
      .includes(:booking, :bsp1_responses)
      .find_by!(id: params[:id])
  end

  def restart
    unless payment_process.pending?
      raise ArgumentError, <<~ERROR.squish
        Transaktion kann nicht zurückgesetzt werden!
        status: #{payment_process.status},
         responses: #{payment_process.bsp1_responses.count}
      ERROR
    end

    payment_process.restart!
    flash["success"] = "Zahlung wurde zurück gesetzt"

    redirect_back(fallback_location: admin_bookings_path)
  end
end
