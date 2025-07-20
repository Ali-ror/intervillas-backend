class AbsenseOfChildPricesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value == 2
    return if unchanged?(record, attribute)
    return unless any_child_prices?(record)

    record.errors.add(attribute, :has_child_prices)
  end

  private

  def any_child_prices?(record)
    record.villa_prices.where(<<~SQL.squish.freeze).any?
         children_under_6  is not null
      or children_under_12 is not null
    SQL
  end

  def unchanged?(record, attribute)
    chg = record.send "#{attribute}_change"
    chg.nil? || chg[0] == chg[1]
  end
end
