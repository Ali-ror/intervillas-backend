RSpec::Matchers.define :have_error do |error_key, on:, **opts|
  match do |actual|
    actual.valid?
    actual.errors[on].find { |string|
      string =~ validation_message(error_key, **opts)
    }.present?
  end

  def validation_message(error_key, **opts)
    Regexp.new(Regexp.escape(I18n.t(error_key, scope: %i[errors messages], **opts)))
  end

  failure_message do |actual|
    "expected #{actual.errors[on].inspect} to include \"#{validation_message(error_key, **opts)}\""
  end

  failure_message_when_negated do |actual|
    "expected #{actual.errors[on].inspect} to not include \"#{validation_message(error_key, **opts)}\""
  end
end

RSpec::Matchers.define :have_flash do |severety, text|
  match do |actual|
    actual.has_css? ".alert-#{severety}", text: text, wait: 5
  end
end

RSpec::Matchers.define :display_date_range_picker_dates do |from_date, to_date|
  dates = [
    from_date.strftime("%d.%m.%Y"),
    to_date.strftime("%d.%m.%Y"),
  ].join(" – ")

  match do |page|
    page.has_content? dates
  end

  failure_message do
    "Expected to find #{dates.inspect} in #{page.text.inspect}"
  end
end
