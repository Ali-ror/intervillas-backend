#
# Findet zu einer Buchung/Anfrage die Boote, die innerhalb des Zeitraums der
# Villa verfügbar sind. Ausgabe ist eine Liste von Booten, die für jeden Tag
# angeben, ob sie verfügbar sind:
#
#     {
#       inquiry_id: Integer
#       start_date: Date                # min. Datum für Boot
#       end_date:   Date                # max. Datum für Boot
#       boats:      Hash<Integer, BoatSpec>
#     }
#
# mit BoatSpec:
#
#     {
#       id:         Integer             # boat.id
#       name:       String              # boat.admin_display_name
#       free:       [Date, [...]]       # Liste von Daten, an denen das Boot NICHT belegt ist
#       group:      "inclusive" | "optional" | "others" | "hidden"
#       selected:   Array<Date>         # wenn Boot ausgewählt, Array mit Start/End-Datum
#     }
#
BoatFinder = Struct.new(:inquiry) do
  include Memoizable

  delegate :villa, :villa_inquiry, :boat_inquiry,
    to: :inquiry

  def initialize(inquiry)
    case inquiry
    when Inquiry
      super
    when Integer
      super Inquiry.includes(:boat_inquiry, villa_inquiry: :villa).find(inquiry)
    else
      raise ArgumentError, "expected Inquiry instance or ID"
    end
  end

  def as_json(*)
    {
      inquiry_id: inquiry.id,
      start_date:,
      end_date:,
      boats:      booked_boats,
    }
  end

  memoize(:start_date, private: true) { villa_inquiry.start_date + 1 }
  memoize(:end_date,   private: true) { villa_inquiry.end_date - 1 }

  memoize(:active_boats, private: true) do
    list = Boat.active
      .where(villa_id: [nil, villa.id])
      .pluck(:id, :model, :matriculation_number, :hidden) # (perf)
    list << inclusive_selected_boat if inclusive_selected_boat
    list
  end

  memoize :booked_boats, private: true do
    view = Grid::View
      .between(start_date, end_date)
      .rentable("Boat", active_boats.map(&:first))

    booked = view.each_with_object(empty_list) do |v, list|
      each_day(v.start_date, v.end_date) do |day|
        list[v.rentable_id][:free].delete(day)
      end
    end

    # Hack? Das ausgewählte Boot (für diese Anfrage) in dem ausgewählten
    # Zeitram wieder "verfügbar" machen
    if selected_boat
      id = selected_boat[:id]
      r  = selected_boat[:range]

      each_day(*r) { booked[id][:free].add(_1) }
      booked[id][:selected] = r
    end

    booked.values
  end

  memoize :selected_boat, nil: true, private: true do
    if boat_inquiry.present?
      {
        id:    boat_inquiry.boat_id,
        range: [boat_inquiry.start_date, boat_inquiry.end_date],
      }
    end
  end

  private

  # Für alle Boote annehmen, dass diese immer verfügbar sind. Im weiteren
  # Verlauf (#booked_boats) werden die Daten entfernt, bei denen das nicht
  # zutrifft.
  def empty_list
    incl_id = villa.inclusive_boat.try(:id)
    opt_ids = villa.optional_boat_ids.sort

    active_boats.each_with_object({}) do |(id, model, mat_no, hidden), list|
      list[id] = {
        id:,
        name:  admin_display_name(id, model, mat_no, hidden),
        free:  SortedSet.new,
        group: boat_group(id, hidden, incl_id, opt_ids),
      }

      each_day(start_date, end_date) do |day|
        list[id][:free].add(day)
      end
    end
  end

  def inclusive_selected_boat
    return if boat_inquiry.blank?

    b = boat_inquiry.boat
    [b.id, b.model, b.matriculation_number, b.hidden]
  end

  def boat_group(id, hidden, incl_id, opt_ids)
    return :hidden    if hidden
    return :inclusive if id == incl_id
    return :optional  if opt_ids.include?(id)

    :others
  end

  # Iteriert über eine Date-Range (start..end), ohne tatsächlich eine Range
  # erzeugen zu müssen und yielded das jeweilige Datum.
  def each_day(range_start, range_end)
    _, s, e, = [start_date, range_start, range_end, end_date].sort
    tmp      = s.dup

    while tmp <= e
      yield tmp
      tmp += 1
    end
    nil
  end

  def admin_display_name(id, model, mat_no, *)
    BoatNameBuilder.new(id, model, mat_no).admin_display_name
  end
end
