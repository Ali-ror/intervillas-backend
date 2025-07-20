module CorporateHelper
  module Context
    def corporate_switch_date
      Rails.configuration.x.corporate_switch_date
    end

    def travel_to_gmbh_era!(...)
      before { maybe_travel_to_gmbh_era(...) }
    end

    def travel_to_corp_era!(...)
      before { maybe_travel_to_corp_era(...) }
    end
  end

  module Example
    def corporate_switch_date
      Rails.configuration.x.corporate_switch_date
    end

    def maybe_travel_to_gmbh_era(offset: rand(2..6).days)
      travel_to corporate_switch_date - offset if Date.current >= corporate_switch_date
    end

    def maybe_travel_to_corp_era(offset: rand(2..6).days)
      travel_to corporate_switch_date + offset if Date.current < corporate_switch_date
    end
  end
end

RSpec.configure do |config|
  config.include CorporateHelper::Example
  config.extend CorporateHelper::Context
end
