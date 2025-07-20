module Grid
  class Scope
    include Memoizable

    attr_reader :rentable_class   # Boat, Villa
    attr_reader :rentable_type    # "Boat", "Villa"
    # AR::Relation, AR::Base or Integer, used to get #ids
    attr_reader :relation
    attr_reader :start_date       # Date, <= end_date
    attr_reader :end_date         # Date, >= start_date

    def initialize(klass, relation, start_date, end_date)
      unless [Villa, Boat].include?(klass)
        raise ArgumentError, "expected rentable to be Villa or Boat"
      end

      @rentable_class = klass
      @rentable_type  = klass.name
      @relation       = relation

      # Datum in richtigen Typ bringen und sortieren
      @start_date, @end_date = [start_date, end_date].map(&:to_date).minmax
    end

    def empty?
      rows.all?(&:empty?)
    end

    memoize(:header)  { Grid::Row.new(:header, start_date, end_date) }
    memoize(:rows)    { load_collection }

    memoize :ids do
      case relation
      when ActiveRecord::Relation
        relation.select(:id)
      when ActiveRecord::Base
        relation.id
      when Integer
        relation
      else
        raise ArgumentError, "expected ID, instance or relation of/for rentable"
      end
    end

    def empty_rentables
      relation.to_a.reject { |r| rows.keys.include? r.id }
    end

    # @returns Hash<RentableId, Grid::Row>
    def load_collection
      grid_view = Grid::View.for_calendar
                            .between(start_date, end_date)
                            .rentable(rentable_type, ids)

      collection = grid_view.each_with_object({}) do |item, rows|
        inq = item.rentable_inquiry
        next unless inq
        rows[item.rentable_id] ||= Grid::Row.new(item.rentable,
                                                 start_date,
                                                 end_date)
        rows[item.rentable_id].add_rentable_inquiry(inq)
      end

      collection.sort_by { |_, v|
        v.title.display_name
      }.to_h
    end
  end
end
