require "rails_helper"

#
# Eigentlich ist dies ein Feature-Spec. Da die Routen für Page-Objekte aber
# dynamisch erzeugt werden und Capybara.app ein Neuladen der Routen nicht so
# einfach erlaubt, habe ich diesen Test als Controller-Spec umgeschrieben.
#
# Dinge, die nicht funktioniert haben:
#
# - Capybara.app.instance_variable_get(:@mapping).first.last.reload_routes!
# - generelle Manipulationen von Capybara.app scheinen zu scheitern
# - Refactoring der routes.rb: Braucht in jedem Fall größere oder Test-spezifische
#   Anpassungen, die ich nicht gewillt war umzusetzen, nur um den Test zum Laufen
#   zu kriegen
#
# Ideen für Gegenmaßnahmen:
#
# - Test-DB mit statischen Sites preseeden? (Problem: Synchronisation mit
#   Produktiv- und Dev-Umgebung)
# - Fallback-Route "/:route_path" => "pages#show" (mit Route.find_by(path:
#   param[:route_path])) anstelle dynamischer Routen? (Problem: Performance,
#   weil nun auch Zugriffe DB-Abragen verursachen, die zuvor gar keine
#   Routen waren)
# - Alles so lassen wie es ist?
#

RSpec.describe Admin::PagesController do
  render_views

  let!(:static_page) {
    create :page, name: "Skipper Haftpflicht", noindex: false, template_path: "skipper_haftpflicht"
  }

  let(:page) { Capybara.string response.body }

  # Capybara::DSL/Capybara::RSpecMatchers machen andere Dinge!
  define :have_link do |href|
    match do |actual|
      selector = 'a[href="%s"]' % href
      actual.has_selector?(selector)
    end
    failure_message              { "expected to find a link to #{expected}" }
    failure_message_when_negated { "expected to find no link to #{expected}" }
  end

  it "renders with German locale" do
    get :show, params: { id: static_page.id, locale: "de" }

    expect(page).to have_link "http://www.schomacker.de/charterversicherungen.html?pid=a1435"
    expect(page).to have_link "http://www.pantaenius-group.com/content/2526"
  end

  it "renders with English locale" do
    get :show, params: { id: static_page.id, locale: "en" }

    expect(page).to have_link "http://www.schomacker.de/en/charter-insurance.html?pid=a1435"
    expect(page).to have_link "http://www.pantaenius-group.com/content/2526"
  end
end
