module Usps
  USPS.username = "09DIGINT52805"

  def self.lookup_zip_plus_four(villa)
    return "#{villa.postal_code}-0000" if Rails.env.test?

    addr = USPS::Address.new.tap { |a|
      a.address = villa.street
      a.city    = villa.locality
      a.zip     = villa.postal_code
      a.state   = villa.region
    }

    req = USPS::Request::ZipCodeLookup.new(addr)
    req.send!.get(addr).zip
  end
end
