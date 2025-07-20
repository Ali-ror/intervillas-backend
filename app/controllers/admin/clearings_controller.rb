class Admin::ClearingsController < ApplicationController
  include Admin::ControllerExtensions

  layout "admin_bootstrap"

  before_action :check_admin!

  expose :owner_clearings do
    next {} unless valid_clearing_date? # XXX: `return` won't work here

    scope = Inquiry.cleared_for(clearing_date)
    Currency::CURRENCIES.each_with_object({}) { |curr, acc|
      acc[curr] = OwnerClearing.from scope.currency(curr).accessible_by(current_ability)
    }
  end

  expose(:customer_search_form) { SearchForms::Customer.from_params current_user, {} }
  expose(:current_month)        { Date.current.beginning_of_month.to_date }
  expose(:year_range)           { current_user.booking_year_range }

  expose :clearing_date do
    year  = params[:year].presence  || current_month.year
    month = params[:month].presence || current_month.month
    Date.new(year.to_i, month.to_i, 1)
  end

  expose :current_owner_reports do
    ClearingReport.by_last_mail_sent_in(clearing_date).index_by do |lob|
      lob.contact_id
    end
  end

  helper_method :valid_clearing_date?

  def index
    respond_to do |format|
      format.html
      format.pdf {
        contacts   = owner_clearings.values.flat_map(&:values).map(&:owner).uniq(&:id)
        collection = ClearingReport::Collection.new(contacts, clearing_date)
        send_file collection.pdf_path,
          disposition: "attachment",
          filename:    collection.pdf_name
      }
    end
  end

  def deliver_single
    clearings = owner_clearings.fetch(params[:currency]).fetch(params[:id].to_i)
    clearings.owner.clearing_reports.create!(reference_month: clearing_date)
    delivery_successful!(clearings.owner)
  rescue KeyError
    flash["error"] = "Fehler: Eigentümer nicht gefunden. Bitte nochmal versuchen."
  ensure
    redirect_to current_month_url
  end

  def deliver_all
    owner_clearings.each do |_, clearings_by_currency|
      clearings_by_currency.each do |owner_id, clearings|
        next if ignore_already_sent?(owner_id)

        clearings.owner.clearing_reports.create!(reference_month: clearing_date)
      end
    end
    delivery_successful!
    redirect_to current_month_url
  end

  private

  def valid_clearing_date?
    year_range.cover? clearing_date.year
  end

  def delivery_successful!(owner = nil)
    rcpt             = owner ? owner.to_s : "alle Eigentümer"
    date             = I18n.l clearing_date, format: "%B %Y"
    flash["success"] = "Versand vorbereitet: Monatsübersicht #{date} an #{rcpt}."
  end

  def current_month_url
    admin_clearings_url(month: clearing_date.month, year: clearing_date.year)
  end

  def ignore_already_sent?(contact_id)
    params[:ignore_already_sent] == "1" && current_owner_reports.key?(contact_id)
  end
end
