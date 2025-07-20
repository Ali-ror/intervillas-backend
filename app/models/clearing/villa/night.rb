class Clearing::Villa::Night < SimpleDelegator
  def evening
    __getobj__
  end

  def morning
    self + 1.day
  end

  def <=>(other)
    evening <=> other.evening
  end
end
