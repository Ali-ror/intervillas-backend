class BigDecimal
  # Override Rails' BigDecimal#as_json method.
  #
  # The original documentation states:
  #
  #   A BigDecimal would be naturally represented as a JSON number. Most libraries,
  #   however, parse non-integer JSON numbers directly as floats. Clients using
  #   those libraries would get in general a wrong number and no way to recover
  #   other than manually inspecting the string with the JSON code itself.
  #
  # However, we don't deal with the general case here. We mostly exchange
  # monetary values with our frontend application. For this case, floats
  # are good enough (and also don't require special handling in JS-land).
  def as_json(options = nil)
    finite? ? to_f : nil
  end
end
