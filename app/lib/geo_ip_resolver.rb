require "maxminddb"

module GeoIpResolver
  Result = Struct.new(:code, :america?, :switzerland?)
  class IPResolver
    attr_reader :db

    def initialize(mmdb)
      @db = MaxMindDB.new mmdb
    end

    def resolve(ip_address)
      result = db.lookup(ip_address.to_s)

      Result.new(result.country.iso_code, %w[NA SA].include?(result.continent.code), result.country.iso_code == "CH")
    end
  end

  class MockResolver
    def initialize(mmdb)
      @mmdb = mmdb.to_s
    end

    def resolve(*)
      unless Rails.env.test?
        Rails.logger.error "[GeoIpResolver] #{@mmdb} does not exist, please run `rake geoip:update`"
      end
      Result.new(nil, nil, nil)
    end
  end

  class << self
    delegate :resolve,
      to: :default_resolver

    def default_resolver
      @default_resolver ||= begin
        mmdb = Rails.root.join("data/GeoLite2-Country.mmdb")
        (mmdb.exist? ? IPResolver : MockResolver).new mmdb
      end
    end
  end
end
