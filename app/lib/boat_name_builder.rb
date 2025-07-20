class BoatNameBuilder < Struct.new(:id, :model, :number)
  def self.from_boat(boat)
    new boat.id, boat.model, boat.matriculation_number
  end

  def initialize(*)
    super
    self.model  = model.to_s.strip.presence
    self.number = number.to_s.strip.presence
  end

  def display_name
    model || id.to_s
  end

  def admin_display_name
    [id, model].compact.join " - "
  end

  alias list_name admin_display_name

  def formatted_matriculation_number
    return nil unless number.present?

    "FL-#{number}"
  end
end
