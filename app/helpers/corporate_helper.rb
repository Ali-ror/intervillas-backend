module CorporateHelper
  def intervilla_corp?
    DateTime.current >= Rails.configuration.x.corporate_switch_date
  end

  def corporate_type
    intervilla_corp? ? :corp : :gmbh
  end
end
