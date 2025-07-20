class Admin::CustomerSearchesController < ApplicationController
  include Admin::ControllerExtensions

  layout 'admin_bootstrap'

  expose(:customer_search_form) { SearchForms::Customer.from_params current_user, params[:customer_search] }
  expose(:results)              { customer_search_form.perform! if customer_search_form.valid? }

end
