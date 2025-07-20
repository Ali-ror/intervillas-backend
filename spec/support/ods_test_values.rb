# Stellt den Zugriff auf die Testwerte in der spec/fixtures/prices.ods bereit.
#
# Testwerte (in Euro und Dollar) werden in der spec/fixtures/prices.ods gesammelt
# und können in den einzelnen Specs auf verschiedene Arten abgerufen werden.
#
class OdsTestValues # rubocop:disable Metrics/ClassLength
  # (perf) cache OdsTestValues instances, as parsing the ODS file and
  # building indices takes a significant amount of time
  #
  # Keys ought to be either Currency::EUR, or Currency::USD.
  CACHE = Hash.new { |h, k| h[k] = OdsTestValues.new(k) }

  def self.for(currency)
    CACHE[currency]
  end

  MissingValue = Class.new(StandardError)

  # Verschiedene wiederverwendbare Konfigurationen für #format_currency bzw.
  # ActiveSupport::NumberHelper::NumberToCurrencyConverter
  #
  # Standardformat für von Rails formatierte Geldwerte
  RAILS_CURRENCY_FORMAT = { delimiter: "'", format: "%u %n" }.freeze
  # nur Hochkomma ohne Währungssymbol
  SWISS_DELIMITER       = { delimiter: "'" }.freeze
  # nur Ziffern
  ONLY_DIGIT            = { format: "%n" }.freeze

  ODS_FILE = "spec/fixtures/prices.ods".freeze

  # @param [String] currency Currency::EUR, Currency::USD
  def initialize(currency)
    @currency = currency

    # @type [Rspreadsheet::Workbook]
    @sheet = Rspreadsheet.open(ODS_FILE)
  end

  # @return [String]
  def symbol
    Currency.symbol(@currency)
  end

  # Wert als Name-Wert-Paar aus dem Worksheet "TestValues" abfragen
  # zur Verwendung mit HelperMethods##expect_price_row_value
  #
  # @param [String] name Name des Werts (steht in der ersten Spalte)
  # @param [Symbol,String] variant Variante des Wertes (steht in der ersten Zeile)
  # @param [TrueClass,FalseClass] format Formatierung als Währung, Standard ist True
  # @param [Hash] format_options Optionen für die Formatierung (@see ActiveSupport::NumberHelper::NumberToCurrencyConverter)
  #
  # @return [Array<String,BigDecimal>]
  def lookup(name, variant = nil, format: true, format_options: {})
    [name, lookup_value(name, variant, format: format, format_options: format_options)]
  end

  #  Wert aus dem Worksheet "TestValues" abfragen
  #
  # @param [String] name Name des Werts (steht in der ersten Spalte)
  # @param [Symbol,String] variant Variante des Wertes (steht in der ersten Zeile)
  # @param [TrueClass,FalseClass] format Formatierung als Währung, Standard ist True
  # @param [Hash] format_options Optionen für die Formatierung (@see ActiveSupport::NumberHelper::NumberToCurrencyConverter)
  #
  # @return [String,BigDecimal]
  def lookup_value(name, variant = nil, format: true, format_options: {})
    row   = find_row(name)
    value = row.cell(find_col(variant || "default")).value
    raise MissingValue, "missing TestValues #{@currency} #{name} #{variant}" if value.nil?

    format ? format_currency(value, options: format_options) : value
  end

  # Wert aus dem Worksheet "TestValues" abfragen
  # zur Verwendung mit #expect_price_row_field oder #have_field
  #
  # @param [String] name Name des Werts (steht in der ersten Spalte)
  # @param [Symbol,String] variant Variante des Wertes (steht in der ersten Zeile)
  #
  # @return [Array<String or Hash{Symbol->String or BigDecimal}>]
  def lookup_field(name, variant = nil)
    [name, { with: lookup(name, variant, format: false)[1] }]
  end

  # Grundpreise aus dem Worksheet "SingleRatesBase" anfragen
  #
  # @param [String,Symbol] name Name des Werts (steht in der ersten Spalte)
  # @param [TrueClass,FalseClass] format Formatierung als Währung, Standard ist True
  # @param [Hash] format_options Optionen für die Formatierung (@see ActiveSupport::NumberHelper::NumberToCurrencyConverter)
  #
  # @return [String,BigDecimal]
  def lookup_category(name, format: true, format_options: {})
    row = category_index.fetch(name)
    col = @currency == Currency::EUR ? 2 : 3

    value = single_rates_base[row, col]
    raise MissingValue, "missing SingleRatesBase #{@currency} #{name}" if value.blank?

    format ? format_currency(value, options: format_options) : value
  end

  # Preise aus dem Worksheet "ChangingTotal" abfragen
  # zur Verwendung mit HelperMethods#expect_normal_price_changing_total
  #
  # @param [String] name Name des Werts (steht in der ersten Spalte)
  # @param [Symbol,String] variant Variante des Wertes (steht in der ersten Zeile)
  #
  # @return [Hash<Symbol,String>] { from:, to:, normal: }
  def lookup_changing_total(name, variant: nil)
    row = changing_total.row(changing_total_index.fetch(name))

    offset  = 0
    offset += 1 if @currency == Currency::USD
    offset += 6 if variant.present?

    from, to, normal = [6, 8, 10].map { |i| row[i + offset] }

    {
      from:   format_currency(from),
      to:     format_currency(to),
      normal: format_currency(normal, options: ONLY_DIGIT),
    }
  end

  # Preise aus dem Worksheet "OwnerBilling" abfragen
  #
  # @param [String] category Kategorie (erste Spalte)
  # @return [String]
  def lookup_owner_billing(category)
    row = owner_billing.row(owner_billing_row_index.fetch(category))

    indices = [2, 3]
    indices.map! { |i| i + 2 } if @currency == Currency::USD

    formatted_values = indices.map { |i| format_currency(row[i], options: RAILS_CURRENCY_FORMAT) }

    [category, *formatted_values].compact.join(" ")
  end

  # Preise aus dem Worksheet "TenantBilling" abfragen
  #
  # @param [String] category Kategorie (erste Spalte)
  #
  # @return [String]
  def lookup_tenant_billing(category)
    row = tenant_billing.row(tenant_billing_row_index.fetch(category))

    indices = [2, 3]
    indices.map! { |i| i + 2 } if @currency == Currency::USD

    [
      category,
      row[indices[0]],
      format_currency(row[indices[1]], options: RAILS_CURRENCY_FORMAT),
    ].compact.join(" ").strip
  end

  # Einzel-Übernachtungspreis für bestimmte Belegung abfragen
  #
  # @param [Integer] occupancy Belegung
  # @param [TrueClass,FalseClass] format Formatierung als Währung, Standard ist True
  # @param [Hash] format_options Optionen für die Formatierung (@see ActiveSupport::NumberHelper::NumberToCurrencyConverter)
  #
  # @return [String, nil]
  def single_rate(occupancy: 2, format: true, format_options: {})
    row = occupancy + 13
    col = @currency == Currency::EUR ? 2 : 3

    value = single_rates_base[row, col]
    raise MissingValue, "missing SingleRatesBase #{@currency} single_rate occupancy: #{occupancy}" if value.blank?

    format ? format_currency(value, options: format_options) : value
  end

  private

  # @param [Rspreadsheet::Worksheet] worksheet
  #
  # @return [ActiveSupport::HashWithIndifferentAccess]
  def index_by_first_row(worksheet)
    worksheet.row(1).cells
      .select { |c| c.value.present? }
      .map    { |c| [c.value, c.index] }
      .to_h
      .with_indifferent_access
  end

  # @param [Rspreadsheet::Worksheet] worksheet
  #
  # @return [ActiveSupport::HashWithIndifferentAccess]
  def index_by_first_column(worksheet)
    worksheet.rows
      .map { |r| [r.cell(1).value, r.index] }
      .to_h
      .with_indifferent_access
  end

  def sheets
    @sheets ||= Hash.new { |cache, name|
      cache[name] = @sheet.worksheets(name)
    }
  end

  {
    owner_billing:     "OwnerBilling",
    tenant_billing:    "TenantBilling",
    changing_total:    "ChangingTotal",
    single_rates_base: "SingleRatesBase",
    test_values:       "TestValues",
  }.each do |method_name, sheet_name|
    define_method(method_name) { sheets[sheet_name] }
  end

  def mod_index
    @mod_index ||= index_by_first_row(test_values)
  end

  def name_index
    @name_index ||= index_by_first_column(test_values)
  end

  def category_index
    @category_index ||= index_by_first_column(single_rates_base)
  end

  def changing_total_index
    @changing_total_index ||= index_by_first_column(changing_total)
  end

  def owner_billing_row_index
    @owner_billing_row_index ||= index_by_first_column(owner_billing)
  end

  def tenant_billing_row_index
    @tenant_billing_row_index ||= index_by_first_column(tenant_billing)
  end

  # @return [String]
  def format_currency(value, options: {})
    return nil unless value

    format_options = PriceHelper::CURRENCY_OPTIONS.fetch(@currency).merge(
      delimiter: ".",
      format:    "%n %u",
    ).merge(options)

    ActiveSupport::NumberHelper::NumberToCurrencyConverter
      .convert(value, format_options)
      .strip
  end

  def find_col(alt)
    index = mod_index.fetch(alt)
    @currency == Currency::EUR ? index : index + 1
  end

  def find_row(key)
    test_values.row(name_index.fetch(key))
  end
end
