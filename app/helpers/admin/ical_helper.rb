module Admin
  module IcalHelper
    def ical_export_url(rentable, include_external: true)
      options = {
        type:             rentable.model_name.route_key,
        id:               rentable.id,
        token:            rentable.ical_token,
        include_external: (include_external ? nil : 0),
      }.compact

      api_ical_url options
    end
  end
end
