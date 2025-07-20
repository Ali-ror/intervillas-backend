require "rails_helper"

RSpec.describe VillasController do
  it { is_expected.to route(:get, "/villas").to    action: "redirect_unlocalized" }
  it { is_expected.to route(:get, "/villas/id").to action: "redirect_unlocalized", id: "id" }

  {
    en: "/vacation-rentals-cape-coral",
    de: "/ferienhaus-cape-coral",
  }.each do |locale, path|
    it { is_expected.to route(:get, path).to         action: "index", locale: locale.to_s }
    it { is_expected.to route(:get, "#{path}/id").to action: "show",  locale: locale.to_s, id: "id" }
  end
end
