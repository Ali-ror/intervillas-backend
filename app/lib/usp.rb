# / USP's - Unique Selling Proposition
class Usp < Struct.new(:locale)
  ENTRIES = YAML.load Rails.root.join('db/usp.yml').read

  def self.all(locale)
    new(locale.to_s)
  end

  delegate :each_with_index, to: :entries
  delegate :each, to: :entries

  def entries
    ENTRIES.fetch(locale)
  end

  # start-delay -> 0, 400, 800, 1200
  # Gibt die verzögerung für die Eingangsanimation an.
  def each_with_start_delay
    each_with_index do |usp, index|
      yield usp, index * 400
    end
  end
end
