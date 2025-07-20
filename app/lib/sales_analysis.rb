# Summiert den Mietpreis aller Buchungen in einem Jahr und dem Vorjahr
# bis zu einem bestimmten Datum auf.
#
class SalesAnalysis
  # @!attribute date
  #   @return [Date] Datum, bis zu dem aufsummiert wird
  attr_accessor :date

  # @!attribute year
  #   @return [BigDecimal] Summe Mietpreis im laufenden Jahr
  attr_accessor :year

  # @!attribute year_net
  #   @return [BigDecimal] Summe Netto Mietpreis im laufenden Jahr
  attr_accessor :year_net

  # @!attribute prev_year
  #   @return [BigDecimal] Summe Mietpreis im Vorjahr
  attr_accessor :prev_year

  # @!attribute prev_year_net
  #   @return [BigDecimal] Summe Netto Mietpreis im Vorjahr
  attr_accessor :prev_year_net

  # @param [Date] date Datum, bis zu dem aufsummiert wird
  def initialize(date)
    self.date = date
  end

  # @param [Date] date Datum, bis zu dem aufsummiert wird
  # @return [SalesAnalysis]
  def self.query(date)
    new(date).tap(&:query)
  end

  def change_net
    [year_net[0] - prev_year_net[0], year_net[1] - prev_year_net[1]]
  end

  # absolute Veränderung gegenüber dem Vorjahr
  #
  # @return [BigDecimal]
  def change
    [year[0] - prev_year[0], year[1] - prev_year[1]]
  end

  # Führt die Auswertung durch.
  # Wird bei Initialisierung über {query} automatisch aufgerufen.
  def query
    self.year     = Currency::CURRENCIES.map { |cur|
      Currency::Value.make_value(
        clearings(date, cur).sum(&:total_rents),
        cur,
      )
    }
    self.year_net = Currency::CURRENCIES.map { |cur|
      Currency::Value.make_value(
        net(villa_inquiries(date, cur).sum(&:billing_rent), sales_tax(date.year), :tourist) +
          net(boat_inquiries(date, cur).compact.sum(&:billing_rent), sales_tax(date.year)),
        cur,
      )
    }

    self.prev_year     = Currency::CURRENCIES.map { |cur|
      Currency::Value.make_value(
        clearings(prev_date, cur).sum(&:total_rents),
        cur,
      )
    }
    self.prev_year_net = Currency::CURRENCIES.map { |cur|
      Currency::Value.make_value(
        net(villa_inquiries(prev_date, cur).sum(&:billing_rent), sales_tax(prev_date.year), :tourist) +
          net(boat_inquiries(prev_date, cur).compact.sum(&:billing_rent), sales_tax(prev_date.year)),
        cur,
      )
    }

    nil
  end

  private

  def boat_inquiries(in_date, currency)
    inquiries(in_date, currency).map(&:boat_inquiry)
  end

  def villa_inquiries(in_date, currency)
    inquiries(in_date, currency).map(&:villa_inquiry)
  end

  def clearings(in_date, currency)
    inquiries(in_date, currency).map(&:clearing)
  end

  def net(gross, *taxes)
    Billing::Position.new(nil, nil, gross, *taxes).net
  end

  def sales_tax(in_year)
    if in_year < 2019
      :sales
    else
      :sales_2019
    end
  end

  def inquiries(date, currency)
    @inquiries                           ||= {}
    @inquiries.fetch(date, {})[currency] ||= Inquiry.joins(:booking)
      .includes(:generic_clearing_items,
        villa:         :inclusive_boat,
        villa_inquiry: :clearing_items,
        boat_inquiry:  %i[clearing_items boat])
      .where("bookings.created_at >= :beginning_of_year AND bookings.created_at <= :date",
        date: date, beginning_of_year: date.beginning_of_year)
      .where(currency: currency)
  end

  def prev_date
    @prev_date ||= date.prev_year
  end
end
