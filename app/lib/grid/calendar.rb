module Grid
  class Calendar
    include Enumerable
    include Memoizable

    attr_reader :rentable

    def initialize(rentable, year)
      @rentable = rentable # Boat-/Villa-Instanz
      @date     = DateTime.new year.to_i, 1, 1
    end

    memoize(:year)          { @date.year }
    memoize(:start_date)    { @date.beginning_of_year }
    memoize(:end_date)      { @date.end_of_year }

    memoize(:rentable_type) { rentable.model_name }
    memoize(:rentable_name) { rentable.admin_display_name }

    memoize(:rows, private: true) { scope.rows[rentable.id] }
    memoize(:scope, private: true) do
      Grid::Scope.new rentable.class, rentable, start_date, end_date
    end
    memoize(:days_per_month, private: true) do
      months.map { |m, _| [m, Time.days_in_month(m.month, m.year)] }.to_h
    end

    memoize(:empty_list, private: true) do
      list = {}
      s = start_date.dup
      while s <= end_date
        list[s] = []
        s >>= 1
      end
      list
    end

    memoize(:months) { rows ? empty_list.merge(rows.months) : empty_list }

    memoize(:utilization) do
      next 0 if rows.nil?

      rentable.utilization start_date, end_date, rows.events
    end

    # Kollisionen sind überlappende Zellen
    def has_collisions?
      grid.any? do |_day, (ante, post)|
        cells = (ante + post).compact
        result = cells.present? && cells.any?(&:overlap?)
        result
      end
    end

    def each(&block)
      grid.each(&block)
    end

    memoize(:grid) do
      # leeres Grid holen
      working_grid = empty_grid

      # Grid mit Events füllen
      months.each_with_index do |(month, split_days), m_index|
        split_days.each do |split_day|
          next if split_day.empty? # ganztägig frei (nichts zu tun)

          day_no = split_day.date.day

          [split_day.ante, split_day.post].each do |ev|
            next unless ev

            cell = Cell.event(ev, split_day.overlap?) if Event === ev

            if ev.start_incl?
              working_grid[day_no][0][m_index + 1] = cell
              working_grid[day_no][1][m_index + 1] = nil unless ev.single? && !ev.end_incl?
            else
              working_grid[day_no][1][m_index + 1] = cell
            end

            next if ev.single?

            (1..(ev.end_date.day - ev.start_date.day) - 1).each do |o|
              next if day_no + o > days_per_month[month]

              working_grid[day_no + o][0][m_index + 1] = nil
              working_grid[day_no + o][1][m_index + 1] = nil
            end

            o = ev.end_date.day - ev.start_date.day
            if day_no + o <= days_per_month[month]
              working_grid[day_no + o][0][m_index + 1] = nil
              working_grid[day_no + o][1][m_index + 1] = nil if ev.end_incl?
            end
          end
        end
      end

      # zusammenhängende leere Tage mergen
      working_grid.each do |_day_of_month, (ante_list, post_list)|
        (1..ante_list.size - 1).each do |i|
          ante = ante_list[i]
          post = post_list[i]

          next if ante.blank?

          if ante&.empty? && post && post.empty?
            ante_list[i] = Cell.empty("", 2)
            post_list[i] = nil
          end
        end
      end

      # fertig, wird in @grid gecacht
      working_grid
    end

    private

    # Erzeugt ein (fast) leeres "Monate×Tage"-Grid, vorbefüllt mit:
    #
    # - der Titel-Zelle ("Tag" am linken Rand)
    # - "blank"-Zellen am Ende des Monats (z.B. für den 30.Feb)
    #
    # Der Rückgabewert wird explizit nicht memoized (wg. Seiteneffekten in #grid)
    #
    # XXX:  Die Graph-Hierarchie ist unintuitiv: Der Zugriff eine bestimmte Zelle
    #       läuft über `grid[index tag][0/1 (ante/post)][index monat]`.
    def empty_grid
      (1..31).map do |day_of_month|
        ante = [Cell.empty(day_of_month, 2)] # Titel-Zelle
        post = [nil]

        months.each do |month, _|
          if day_of_month > days_per_month[month]
            # 29.Feb (je nach Jahr), 30.Feb, 31.Feb/Apr/Jul/Sep/Nov (jedes Jahr)
            ante << Cell.blank(1)
            post << Cell.blank(1)
          else
            ante << Cell.empty("", 1)
            post << Cell.empty("", 1)
          end
        end

        [day_of_month, [ante, post]]
      end.to_h
    end
  end
end
