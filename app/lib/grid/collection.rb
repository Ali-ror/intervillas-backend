module Grid
  class Collection
    attr_reader :start_date # Anfangsdatum (inkl.)
    attr_reader :end_date   # Enddatum (inkl.)

    def initialize(from, to)
      @start_date = from.to_date
      @end_date   = to.to_date
    end

    def scope(klass, relation)
      Grid::Scope.new klass, relation, @start_date, @end_date
    end

    def villas(relation)
      scope Villa, relation
    end

    def boats(relation)
      scope Boat, relation
    end
  end
end
