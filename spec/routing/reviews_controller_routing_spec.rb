require "rails_helper"

RSpec.describe ReviewsController do
  {
    en: "/reviews",
    de: "/bewertungen",
  }.each do |locale, path|
    it { is_expected.to route(:get, path).to action: "index", locale: locale.to_s }
  end

  {
    en: "/vacation-rentals-cape-coral/villa_id/reviews",
    de: "/ferienhaus-cape-coral/villa_id/bewertungen",
  }.each do |locale, path|
    it { is_expected.to route(:get, path).to action: "index", villa_id: "villa_id", locale: locale.to_s }
  end

  it { is_expected.to route(:get,  "/villas/villa_id/bewertungen").to        action: "redirect_unlocalized", villa_id: "villa_id" }
  it { is_expected.to route(:get,  "/villas/villa_id/reviews/id").to         action: "show", id: "id", villa_id: "villa_id" }
  it { is_expected.to route(:get,  "/villas/villa_id/reviews/id/edit").to    action: "edit", id: "id", villa_id: "villa_id" }
  it { is_expected.to route(:put,  "/villas/villa_id/reviews/id").to         action: "update", id: "id", villa_id: "villa_id" }
  it { is_expected.to route(:post, "/villas/villa_id/reviews/id/preview").to action: "preview", id: "id", villa_id: "villa_id" }
end
