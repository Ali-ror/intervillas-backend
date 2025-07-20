Billing::Position = Struct.new(:subject, :context, :gross, :taxes) do
  attr_reader :net, :tax, :proportions

  def initialize(subject, context, gross, *tax_names)
    super subject, context, gross, Taxable.find_taxes(*tax_names)

    @net = Taxable.to_net(gross, taxes.values.sum)
    @tax = gross - net

    # Liefert für jede Steuer den Anteil
    @proportions = taxes.map { |name, percentage|
      [name, @net * percentage]
    }.to_h
  end

  def valid?(epsilon = 1e-16)
    gross - (net + proportions.values.sum) < epsilon
  end
end
