module Billing::Csv
  extend ActiveSupport::Concern

  class NullBilling
    def to_s
      ""
    end

    def to_f
      nil
    end

    def method_missing(*)
      self
    end

    def respond_to_missing?(*)
      false
    end
  end

  included do
    comma :summary do
      owner                   "Owner"
      csv_tax_id              "TIN"
      csv_rentable            "Object"
      csv_number              "Invoce #"
      csv_name                "Renter name"
      csv_start_date          "Date (arrival)"
      csv_end_date            "Date (departure)"
      csv_days                "# of days"
      csv_summary_currency    "Currency"
      csv_rent_house          "Net rent house"
      csv_net_cleaning        "Net cleaning"
      csv_net_energy          "Net energy (electricity)"
      csv_sales_tax_house     "Sales tax (house)"
      csv_tourist_tax_house   "Tourist tax (house)"
      csv_boat_name           "Boat name"
      csv_rent_boat           "Net rent boat"
      csv_net_boat_training   "Net boat training"
      csv_sales_tax_boat      "Sales tax (boat)"
      csv_accounting          "Total excluding taxes"
      csv_taxes               "Taxes total"
      csv_agency_fee          "Admin Agency Fee"
      csv_agency_commission   "Agency Commission"
      csv_payout              "Payout"
    end

    delegate :number, :name, :summary_currency, :boat_name,
      to: :booking, prefix: "csv"

    delegate :summary_on,
      to: :booking

    delegate :start_date, :end_date, :days,
      to: :main_billing, prefix: "csv"
  end

  def csv_tax_id
    owner&.tax_id_number
  end

  def csv_rentable
    main_billing.rentable.admin_display_name
  end

  def csv_villa_billing
    villa_billing || NullBilling.new
  end

  def csv_boat_billing
    boat_billing || NullBilling.new
  end

  def csv_rent_house
    round_csv csv_villa_billing.rent.net
  end

  def csv_net_cleaning
    round_csv csv_villa_billing.cleaning.net
  end

  def csv_sales_tax_house
    round_csv csv_villa_billing.total.proportions[sales_tax_identifier]
  end

  def csv_tourist_tax_house
    round_csv csv_villa_billing.total.proportions[:tourist]
  end

  def csv_net_energy
    round_csv csv_villa_billing.energy_unfeed.net
  end

  def csv_rent_boat
    round_csv csv_boat_billing.rent.net
  end

  def csv_net_boat_training
    round_csv csv_boat_billing.training.net
  end

  def csv_sales_tax_boat
    round_csv csv_boat_billing.total.tax
  end

  def csv_accounting
    round_csv accounting
  end

  def csv_taxes
    round_csv taxes
  end

  def csv_agency_fee
    round_csv agency_fee
  end

  def csv_agency_commission
    round_csv agency_commission
  end

  def csv_payout
    round_csv payout
  end

  private

  def round_csv(val)
    val.round(2).to_d
  end

  def sales_tax_identifier
    if (summary_on || Date.current).year >= 2019
      :sales_2019
    else
      :sales
    end
  end
end
