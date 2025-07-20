require "rails_helper"

RSpec.describe RequestDomain do
  describe "#canonical_link_tag" do
    subject(:tag) { view.send :canonical_link_tag }

    let(:current_page) { create :page, domains: domains, no_domain: true }
    let(:view) do
      Class.new do
        include RequestDomain::SEOSpamHelper

        def current_domain
          @current_domain ||= FactoryBot.create :domain, interlink: false
        end

        def params
          {
            controller: "admin/pages",
            action:     "show",
          }
        end

        attr_accessor :page

        def request
          ActionController::TestRequest.new({}, {}, Admin::PagesController)
        end

        def url_for(*_args)
          "foo"
        end

        include ActionView::Helpers::TagHelper
      end.new
    end
    let!(:default_domain) { create :domain, :default_domain }

    before do
      view.page = current_page
    end

    context "Page mit mehreren Domains" do
      let(:domains) { create_list :domain, 2 }

      it "enthält canonical Tag" do
        expect(tag).not_to be_blank
      end
    end
    context "Page mit einer Domain" do
      let(:domains) { create_list :domain, 1 }

      it "enthält kein canonical Tag" do
        expect(tag).to be_blank
      end
    end
  end
end
