require "rails_helper"

RSpec.describe Admin::PagesController do
  render_views

  let(:primary_domain)    { Domain.find_by!(default: true) }
  let(:secondary_domain)  { create :domain, name: "cape-coral-ferienhaeuser.com" }

  let(:shared_page)       { create :page, name: "shared page",        no_domain: true }
  let(:primary_page)      { create :page, name: "extra special page", no_domain: true }
  let(:secondary_page)    { create :page, name: "extra special page", no_domain: true }

  before do
    shared_page.domains << primary_domain << secondary_domain
    primary_page.domains << primary_domain
    secondary_page.domains << secondary_domain
  end

  def check_page(host, page)
    @request.host = host
    @request.path = "/#{page.route.path}"
    get :show, params: { id: page.id }

    contents = Capybara.string(response.body).find(".content-page").text
    expect(contents).to include page.content
  end

  it "ensures the same path for primary/secondary page" do
    expect(primary_page.route.path).to eq secondary_page.route.path
  end

  context "on primary domain" do
    let(:host) { "www.intervillas-florida.com" }

    it { check_page host, shared_page }
    it { check_page host, primary_page }
  end

  context "on secondary domain" do
    let(:host) { "www.cape-coral-ferienhaeuser.com" }

    it { check_page host, shared_page }
    it { check_page host, secondary_page }
  end
end
