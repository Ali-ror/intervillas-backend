module Clearing::CommonTotals
  def total_deposit
    deposits.sum(&:total)
  end

  def total_rents
    rents.sum(&:total)
  end

  def total_reversal
    reversals.sum(&:total)
  end

  def total_discount
    discounts.sum(&:total)
  end
end
