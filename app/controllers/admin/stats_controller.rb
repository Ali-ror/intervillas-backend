class Admin::StatsController < ApplicationController
  include Admin::ControllerExtensions
  layout "admin_bootstrap"

  before_action :check_admin!

  helper_method :count_data, :rents, :agency_commission

  expose(:villas) { current_user.villas.active.order(:name) }
  expose(:boats) { current_user.boats.active.order(:id) }

  expose :rentables do
    case params[:type]
    when "villas"
      villas.active
    when "boats"
      boats.active
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  expose :rentable, nil: true do
    rentables.find params[:id] if params[:type] && params[:id]
  end

  expose :events do
    current_user.booking_year_range.map { |y|
      start_date = "#{y}-01-01".to_date.beginning_of_year

      # Hash<rentable_type, Hash<rentable_id, Array<Grid::View>>
      items = Hash.new { |types, type| types[type] = Hash.new { |ids, id| ids[id] = [] } }
      Grid::View.between(start_date, start_date.end_of_year).each do |gv|
        items[gv.rentable_type][gv.rentable_id] << gv
      end

      [y, items]
    }.to_h
  end

  private

  def rents(year, currency)
    val = rentable.rentable_inquiries.booked.in_year(year).with_currency(currency).sum(&:billing_rent)
    Currency::Value.make_value(val, currency)
  end

  def agency_commission(year, currency)
    val = rentable.rentable_inquiries.booked.in_year(year).with_currency(currency).sum(&:agency_commission)
    Currency::Value.make_value(val, currency)
  end

  def count_data(item, year) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    start_date = "#{year}-01-01T00:00:00".to_time(:utc)
    end_date   = "#{year}-12-31T23:59:59".to_time(:utc)
    format     = "%d"

    n = case item
    when :inquiries, :admin_inquiries, :external
      scope = rentable.inquiries.complete
        .between_time(start_date, end_date, rentable: rentable.model_name.singular)
      scope = scope.where(admin_submitted: true) if item == :admin_inquiries
      scope = scope.where(external: true) if item == :external
      scope.count

    when :bookings
      rentable.bookings.in_year(year).count

    when :utilization
      format = "%d %%"
      rentable.utilization start_date.to_date, end_date.to_date,
        events[year][rentable.model_name.to_s][rentable.id]

    when :iv_utilization
      format = "%d %%"
      rentable.utilization start_date.to_date, end_date.to_date,
        events[year][rentable.model_name.to_s][rentable.id].select(&:regular_inquiry)

    when :owner_utilization
      format = "%d %%"
      rentable.utilization start_date.to_date, end_date.to_date,
        events[year][rentable.model_name.to_s][rentable.id].reject(&:regular_inquiry)

    when :people, :adults, :children_under_12, :children_under_2
      format = "%0.2f"
      avg_people[year]&.send "n_#{item}"
    end

    formatted = format(format, n.to_d || 0)
    return formatted if n && n > 0

    view_context.tag.span(formatted, class: "text-muted")
  end

  memoize :avg_people, private: true do
    selects = [
      "extract('year' from villa_inquiries.start_date)::int as y",
      "avg(villa_inquiries.adults + villa_inquiries.children_under_12 + villa_inquiries.children_under_6) as n_people",
      "avg(villa_inquiries.adults) as n_adults",
      "avg(villa_inquiries.children_under_12) as n_children_under_12",
      "avg(villa_inquiries.children_under_6) as n_children_under_6",
    ].join ", "

    rentable
      .villa_inquiries
      .joins(:booking)
      .select(selects)
      .group("y")
      .index_by { |vi| vi.y }
  end
end
