#
# Valditator for federal states/cantons. For some countries, we have a
# defined set of state codes, other countries only have a free text field
# which must be filled in.
#
class StateCodeValidator < ActiveModel::EachValidator
  PRESENCE = ->(v) { v.present? ? nil : :blank }
  ABSENCE  = ->(v) { v.blank? ? nil : :present }

  STATE_NAMES = I18n.t("state_names").stringify_keys.transform_values { |v|
    if v.is_a?(Hash)
      allowed = v.keys - [:label]
      ->(v) { PRESENCE.call(v) || (allowed.include?(v.to_sym) ? nil : :inclusion) }
    else
      PRESENCE
    end
  }.freeze

  def validate_each(record, attribute, value)
    return if record.country.blank?

    err = STATE_NAMES.fetch(record.country, ABSENCE).call(value)
    record.errors.add(attribute, err) if err
  end
end
