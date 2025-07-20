class Admin::SummariesController < AdminController
  defaults resource_class: Booking

  before_action :check_admin!

  helper_method :current_month, :currency_param, :grouping_param

  layout "admin_bootstrap"

  expose :owner_billings do
    collection.map { |b| b.to_billing.owner_billings }.flatten
  end

  def index
    respond_to do |format|
      format.html
      format.csv {
        fname = "Summary-#{current_month.strftime(whole_year? ? '%Y' : '%Y-%m')}-#{currency_param}"
        render csv: owner_billings.to_a, style: :summary, filename: fname
      }
    end
  end

  private

  def current_month
    @current_month ||= begin
      month = !whole_year? && params[:month] =~ /\A([1-9]|1[012])\z/ ? Regexp.last_match(1).to_i : Date.current.month
      year  = params[:year].presence =~ /\A(\d{4})\z/ ? Regexp.last_match(1).to_i : Date.current.year

      Date.parse "#{year}-#{month}-01"
    end
  end

  def whole_year?
    params.key?(:month) && params[:month].blank?
  end

  def group_by_start_date?
    grouping_param == "start_date"
  end

  def collection
    @bookings ||= end_of_association_chain
      .with_billing_in(current_month, whole_year?, group_by_start_date?)
      .currency(currency_param)
      .accessible_by(current_ability)
  end

  def currency_param
    params.fetch(:currency, Currency::EUR)
  end

  def grouping_param
    params.fetch(:grouping, "summary_on")
  end
end
