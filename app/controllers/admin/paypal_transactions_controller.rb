class Admin::PaypalTransactionsController < ApplicationController
  include Admin::ControllerExtensions

  layout 'admin_bootstrap'
  before_action :check_admin!

  expose :paypal_payments do
    PaypalPayment
      .order(id: :desc)
      .paginate(per_page: 20, page: (params[:page] || 1))
  end

  expose :paypal_payment do
    PaypalPayment
      .includes(:inquiry, :paypal_webhooks)
      .find_by!(transaction_id: params[:id])
  end
end
