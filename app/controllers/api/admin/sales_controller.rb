class Api::Admin::SalesController < ApplicationController
  include Admin::ControllerExtensions

  def index
    @analysis = SalesAnalysis.query(params[:date].to_date)
  end
end
