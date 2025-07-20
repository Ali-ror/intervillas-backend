# Übernachtungszeitraum
#
# - enthält mindestens einen Eintrag pro gebuchter Preiskategorie
# - Zeiträume mit gleicher Belegung für eine einzelne Kategorie werden zusammengefasst
class Clearing::Villa::NightCollection
  def initialize
    # @type [Hash{Array<Array<Clearing::Villa::Night>,Clearing::SingleRate>->Array<Traveler>}]
    @occupancy = {}
  end

  def each(&block)
    @occupancy.each(&block)
  end

  # Fügt eine Nacht mit den übergebenen Reisenden und dem Preis hinzu.
  #
  # Direkt beim Einfügen werden Zeiträume mit gleicher Belegung pro Kategorie
  # zusammengefasst.
  def add(night, travelers, single_rate)
    # gleiche Belegung wie letzte Nacht?
    if travelers == last_travelers && single_rate == last_rate && @last_night
      # Zeitraum um diese Nacht "erweitern"
      add_night(night)
    else
      # Neuen Zeitraum erstellen
      @occupancy[[[night], single_rate]] = travelers
    end
    @last_travelers = travelers
    @last_night     = night
    @last_rate      = single_rate
  end

  private

  # Zeitraum um eine Nacht "erweitern"
  def add_night(night)
    @occupancy.keys.find { |n, _r| n.include?(@last_night) }.first << night
  end

  def last_travelers
    @last_travelers || []
  end

  def last_rate
    @last_rate || []
  end
end
