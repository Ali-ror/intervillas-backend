namespace :geoip do
  desc "GeoIP-Datenbank aktualisieren"
  task update: :environment do
    # wir interessieren uns hier nur für die Country-Codes
    uri       = URI "https://download.maxmind.com/app/geoip_download"
    uri.query = {
      edition_id:  "GeoLite2-Country",
      license_key: "F5fHB7Cm5f8qM3l3", # registriert auf dom+madmind@digineo.de
      suffix:      "tar.gz",
    }.map { |k, v| "#{k}=#{v}" }.join("&")

    db_file   = "GeoLite2-Country.mmdb"
    data_dir  = Pathname.new(__dir__).join("../../data").tap(&:mkpath)
    data_file = data_dir.join(db_file)

    # tar.gz abholen und entpacken, aber nur, wenn notwendig
    Net::HTTP.start uri.host, uri.port, use_ssl: uri.scheme == "https" do |http|
      puts "[geoip:update] fetching database"
      req = Net::HTTP::Get.new uri, {
        "If-Modified-Since" => (data_file.mtime.httpdate if data_file.exist?),
      }.compact

      case res = http.request(req)
      when Net::HTTPNotModified
        puts "[geoip:update] no update needed"

      when Net::HTTPOK
        require "rubygems/package"
        require "rubygems/package/tar_reader"
        require "tempfile"

        puts "[geoip:update] extracting mmdb file"
        tgz_io  = StringIO.new(res.body)
        reader  = Gem::Package::TarReader.new Zlib::GzipReader.new tgz_io
        mmdb    = reader.find { |f| File.basename(f.full_name) == db_file }
        raise "#{db_file} not found" unless mmdb

        puts "[geoip:update] copy mmdb file to final destination"
        Tempfile.create([db_file, ".tmp"], data_dir, encoding: "binary").tap do |tmp|
          tmp.write mmdb.read
          tmp.flush
          tmp.close

          FileUtils.mv(tmp, data_file)
        rescue StandardError
          FileUtils.rm(tmp) if File.exist?(tmp)
          raise
        end
      else
        raise "[geoip:update] unexpected response: #{res.code} #{res.message}"
      end
    end
  end
end
