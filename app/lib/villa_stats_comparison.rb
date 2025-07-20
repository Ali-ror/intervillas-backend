# Vergleich von Buchungsstatistiken zum Vorjahr nach Monat
#
class VillaStatsComparison
  include Enumerable
  include DigineoExposer::Memoizable

  attr_accessor :villa, :prev_year, :year

  # @!attribute months
  #   @return [Array<Month>] months alle Monate eines Jahres
  attr_reader :months

  delegate :each, to: :months

  # Erstellt Auswertung
  #
  # @param [Villa] villa
  # @param [Integer] year Das Jahr, für das die Auswertung erstellt wird
  #
  # @return [VillaStatsComparison]
  def self.query(villa, year)
    new(villa, year).tap(&:query)
  end

  # @param [Villa] villa
  # @param [Integer] year Das Jahr, für das die Auswertung erstellt wird
  #
  # @return [VillaStatsComparison]
  def initialize(villa, year)
    self.villa     = villa
    self.year      = year
    self.prev_year = year - 1

    @months = (1..12).map do |n|
      Month.new(n)
    end
  end

  # Sammelt die Statistiken
  def query
    %i[prev_year year].each do |year_key|
      year = send(year_key)

      start_date = "#{year}-01-01T00:00:00".to_time(:utc)
      end_date   = "#{year}-12-31T23:59:59".to_time(:utc)

      inquiries = villa.inquiries.complete
                       .between_time(start_date, end_date, rentable: villa.model_name.singular)

      group(inquiries, as: :inquiries, year_key: year_key)

      group(inquiries.where(admin_submitted: true),
            as: :admin_inquiries, year_key: year_key)

      group(villa.bookings.in_year(year), as: :bookings, year_key: year_key)

      villa.utilization_in_year_by_month(year).each do |month, utilization|
        months[month - 1].fetch(:utilization)[year_key] = utilization
      end

      months.each do |month|
        month.fetch(:people)[year_key] =
          avg_people.fetch(year, {}).fetch(month.number, NullObject.new).n_people
        month.fetch(:adults)[year_key] =
          avg_people.fetch(year, {}).fetch(month.number, NullObject.new).n_adults
        month.fetch(:children_under_6)[year_key] =
          avg_people.fetch(year, {}).fetch(month.number, NullObject.new).n_children_under_6
        month.fetch(:children_under_12)[year_key] =
          avg_people.fetch(year, {}).fetch(month.number, NullObject.new).n_children_under_12
      end
    end
  end

  class NullObject
    def method_missing(*)
      0
    end
  end

  private

  memoize :avg_people, private: true do
    selects = [
      "extract('year' from villa_inquiries.start_date)::int as year",
      "extract('month' from villa_inquiries.start_date)::int as month",
      "avg(villa_inquiries.adults + villa_inquiries.children_under_12 + villa_inquiries.children_under_6) as n_people",
      "avg(villa_inquiries.adults) as n_adults",
      "avg(villa_inquiries.children_under_12) as n_children_under_12",
      "avg(villa_inquiries.children_under_6) as n_children_under_6"
    ].join ", "

    villa
      .villa_inquiries
      .joins(:booking)
      .select(selects)
      .group("year, month")
      .map { |vi| [vi.year, vi.month, vi] }
      .each_with_object({}) do |(year, month, vi), acc|
        acc[year] ||= {}
        acc[year][month] = vi
      end
  end

  # @param [ActiveRecord::Relation] collection
  # @param [Symbol] as Name der "Datenserie"
  # @param [Symbol] year_key Jahr (:year) oder Vorjahr (:prev_year)
  def group(collection, as:, year_key:)
    collection
      .group_by { |i| i.start_date.month }
      .each { |m, is| months[m - 1].fetch(as)[year_key] = is.count }
  end

  class Month
    attr_reader :number

    # @param [Integer] number Nummer des Monats (1-12)
    def initialize(number)
      @number = number
      @containers = {}
    end

    # Gibt den Container mit entsprechendem Namen zurück
    #
    # Container wird bei Bedarf erstellt und im Cache abgelegt
    #
    # @param [Symbol] container Name des Containers
    # @return [Container]
    def fetch(container)
      @containers[container] ||= @containers.fetch(container, Container.new)
    end

    # Container für Monats-Daten
    class Container
      attr_writer :prev_year, :year

      # absolute Veränderung (Differenz)
      # @return [Numeric]
      def change
        year - prev_year
      end

      # Daten des Jahres
      # @return [Numeric]
      def year
        @year || 0
      end

      # Daten des Vorjahres
      # @return [Numeric]
      def prev_year
        @prev_year || 0
      end

      # setzt einen Wert
      #
      # @param [Symbol] year_key Jahr (:year) oder Vorjahr (:prev_year)
      # @param [Numeric] value
      def []=(year_key, value)
        writer_key = year_key.to_s + "="
        return super unless respond_to?(writer_key)

        send(writer_key, value)
      end
    end
  end
end
