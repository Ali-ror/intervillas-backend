class ConflictingMinimumPeopleValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if min_people(record) == 2

    record.errors.add(attribute, :conflicting_minimum_people)
  end

  private

  def min_people(record)
    record.villa&.minimum_people || 2
  end
end
