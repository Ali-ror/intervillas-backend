require "addressable/template"

module WeatherForecast
  extend self

  CURRENT  = Addressable::Template.new("https://api.openweathermap.org/data/2.5/weather{?query*}").freeze
  FORECAST = Addressable::Template.new("https://api.openweathermap.org/data/2.5/forecast{?query*}").freeze

  LOCATIONS = {
    cape_coral: { lat: "26.5629", lon: "-81.9495" },
  }.freeze

  CONDITIONS = YAML.load_file(Rails.root.join("config/openweathermap.yml")).freeze

  def find(location)
    loc = location.to_sym

    f                 = Rails.root.join("data/weather-#{loc}.json")
    data              = JSON.parse(f.read).try(:with_indifferent_access) if f.exist?
    data[:updated_at] = Time.zone.parse(data[:updated_at]) if data

    data if data && data[:updated_at] > 1.hour.ago
  end

  def update!
    LOCATIONS.to_h do |loc, coord|
      current  = fetch_current(**coord)
      forecast = fetch_forecast(**coord)

      data = {
        updated_at: Time.current,
        weather:    [current, *forecast],
      }.with_indifferent_access

      Rails.root.join("data/weather-#{loc}.json").open("w") do |f|
        f.write data.to_json
      end

      [loc, data]
    end
  end

  # @private
  def api_key
    @api_key ||= case Rails.env
    when "production" then "6225df6c2558d8e8716a484fe437923d"
    when "test"       then "-" # skip in tests
    else                   "55469b191e05fc3025fc3169bdcf94d4" # staging key
    end
  end

  # @private
  def to_fahrenheit(celsius)
    ((celsius * (9/5r)) + 32).round
  end

  # @private
  def extract_relevant_data(data)
    dt       = data.fetch("dt")
    id       = data.dig("weather", 0, "id")
    main     = data.fetch("main")
    min, max = main.values_at("temp_min", "temp_max")

    {
      timestamp: Time.zone.at(dt).in_time_zone("America/New_York"), # TODO: TZ depends on LOCATION
      condition: id,
      high:      [max.round(1), to_fahrenheit(max)],
      low:       [min.round(1), to_fahrenheit(min)],
    }
  end

  # @private
  def fetch_current(lat:, lon:)
    return if api_key == "-"

    data   = JSON.parse Net::HTTP.get CURRENT.expand(query: {
      lat:   lat,
      lon:   lon,
      appid: api_key,
      units: "metric",
      lang:  "en",
    })

    values = extract_relevant_data(data)
    values.merge(
      timestamp: values[:timestamp].strftime("%Y-%m-%d"),
      condition: CONDITIONS.fetch(values[:condition]),
    )
  end

  # @private
  def fetch_forecast(lat:, lon:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return if api_key == "-"

    data = JSON.parse Net::HTTP.get FORECAST.expand(query: {
      lat:   lat,
      lon:   lon,
      appid: api_key,
      units: "metric",
      lang:  "en",
    })

    return unless (list = data.dig("list"))

    # collect conditions and min/max temperature for each day
    forecast = list.each_with_object(Hash.new { |h, k|
      h[k] = {
        cond: [],
        high: [-Float::INFINITY, nil],
        low:  [Float::INFINITY, nil],
      }
    }) { |item, memo|
      values = extract_relevant_data(item)

      t, cond, high, low = values.values_at(:timestamp, :condition, :high, :low)
      id                 = t.strftime("%Y-%m-%d")

      memo[id][:cond] << cond if (6..23).include?(t.hour) # ignore conditions in the night
      memo[id][:high]  = high if high[0] > memo[id][:high][0]
      memo[id][:low]   = low  if low[0] < memo[id][:low][0]
    }

    forecast.map { |t, values|
      freq               = values[:cond].tally
      dominant_condition = values[:cond].max_by { |v| freq[v] }
      next if dominant_condition.nil?

      {
        timestamp: t,
        condition: CONDITIONS.fetch(dominant_condition),
        high:      values[:high],
        low:       values[:low],
      }
    }.compact
  end
end
