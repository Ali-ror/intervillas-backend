module ClearingHelpers
  def expect_clearing_item(on:, **ci_kwargs)
    expect(on.clearing.clearing_items).to(
      include have_attributes(**ci_kwargs)
    )
  end

  def expect_no_clearing_item(on:, **ci_kwargs)
    expect(on.clearing.clearing_items).to_not(
      include have_attributes(**ci_kwargs)
    )
  end
end

RSpec.configure do |config|
  config.include ClearingHelpers
end
