class Api::Admin::InquiryBaseController < ApplicationController
  include Admin::ControllerExtensions

  helper_method :localized_inconsistencies

  expose(:villas) do
    villas = current_user.villas.includes(:villa_price_eur, :villa_price_usd).order(:name)
    action_name == "new" ? villas.active : villas
  end

  private

  def localized_inconsistencies(inquiry)
    i = InquiryConsistencyChecker.new(inquiry).inconsistencies
    render_to_string \
      partial: "admin/inquiries/inconsistencies",
      formats: [:html],
      locals:  { inconsistencies: i }
  end
end
