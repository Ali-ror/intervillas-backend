module Users::AccessLevels
  extend ActiveSupport::Concern

  # Die Reihenfolge (Zugriffslevel absteigend) ist für #access_level= wichtig. Wenn
  # sich daran etwas ändern soll (oder diese Hierarchie keine lineare Abhängigkeit
  # mehr darstellt), dann muss vermutlich #access_level= neu implementiert werden.
  ACCESS_LEVEL = {
    "admin".freeze      => ->(u) { !u.access_locked? && u.admin? },
    "inquiries".freeze  => ->(u) { !u.access_locked? && u.access_bookings? && u.access_inquiries? },
    "bookings".freeze   => ->(u) { !u.access_locked? && u.access_bookings? },
    "rentables".freeze  => ->(u) { !u.access_locked? },
    "none".freeze       => ->(u) { u.access_locked? },
  }.tap {|h|
    h.default = proc { false }
  }.freeze

  included do
    scope :with_access, -> { where locked_at: nil }
    scope :without_access, -> { where.not locked_at: nil }
  end

  def access_level?(level)
    ACCESS_LEVEL[level.to_s.downcase].call(self)
  end

  def has_access? # deprecated
    !access_locked?
  end

  def access_level
    return @access_level if @access_level
    ACCESS_LEVEL.each do |level, check|
      return @access_level = level if check.call(self)
    end
    @access_level = "none".freeze
  end

  def access_level=(level)
    lvl = level.to_s.downcase
    keys = ACCESS_LEVEL.keys

    self.admin            = keys[0, 1].include?(lvl)
    self.access_inquiries = keys[0, 2].include?(lvl)
    self.access_bookings  = keys[0, 3].include?(lvl)

    if keys[0, 4].include?(lvl)
      self.locked_at = nil
      @access_level = lvl
    else
      self.locked_at ||= Time.current
      @access_level = "none".freeze
    end
  end

  def blank_password?
    encrypted_password.blank?
  end

end
