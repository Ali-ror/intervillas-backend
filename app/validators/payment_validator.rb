#
# Zahlungseingänge > 0, Rückzahlungen < 0.
# nil und 0 sind ungültig.
#
class PaymentValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :inclusion) if value.nil? || value.zero?
  end
end
