module Ical
  Downloader = Struct.new(:url) do
    def events
      @ical_data = http.get(url).body
      @recv_date = Time.current

      Event.parse(@ical_data, url)
    end

    def keep_data!
      return if @kept

      base  = url.to_s.downcase.gsub(/[^-.0-9a-z]+/, "_").gsub(/_+/, "_")
      fname = @recv_date.strftime "%Y%m%d_%H%M%S.ical"

      Rails.root
        .join("data/ical-sync", base)
        .tap(&:mkpath)
        .join(fname)
        .open("wb") { |f| f.write @ical_data }
      @kept = true
    end

    private

    def http
      @http ||= Faraday.new do |client|
        client.response :encoding
        client.response :follow_redirects
        client.adapter :net_http
      end
    end
  end
end
