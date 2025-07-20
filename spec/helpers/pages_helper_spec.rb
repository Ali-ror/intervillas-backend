require "rails_helper"

RSpec.describe PagesHelper do
  describe "#render_page_content" do
    let(:content) { <<~HTML }
      <h1>intervillas_address(dl)</h1>
      %intervillas_address(dl)%

      <h1>intervillas_address(breaks)</h1>
      %intervillas_address(breaks)%

      <h1>intervillas_address(break)</h1>
      <!-- typo, should be blank -->
      %intervillas_address(break)%

      <h1>intervillas_bank_account</h1>
      %intervillas_bank_account%

      <h1>intervillas_bank_accounts</h1>
      %intervillas_bank_accounts%

      <h1>intervillas_tax_info</h1>
      %intervillas_tax_info%

      <h1>intervillas_jurisdiction</h1>
      %intervillas_jurisdiction%

      <h1>unknown func</h1>
      %intrevillas(arg)%
    HTML

    def render_page_content(content)
      page   = build(:page, content: content, no_domain: true)
      output = helper.render_page_content page
      output.chomp
    end

    def expect_render_to_match_fixture(fixture_name)
      expected = render_page_content(content)
      fixture  = Rails.root.join("spec/fixtures/pages_helper/#{fixture_name}.html")
      fixture.open("w") { _1.write expected } if ENV["WRITE_FIXTURES"]
      expect(fixture.read).to eq(expected)
    end

    context "Intervilla GmbH" do
      travel_to_gmbh_era! offset: 1.second

      it { expect_render_to_match_fixture("gmbh") }
    end

    context "Intervilla Corp" do
      travel_to_corp_era! offset: 0

      it { expect_render_to_match_fixture("corp") }
    end

    context "carousel image url" do
      let(:image) { create :image, parent: create(:villa) }

      it "return media path" do
        media_path = helper.media_path(image, preset: :carousel)
        expect(render_page_content("%carousel(#{image.id})%")).to eq(media_path)
      end

      it "fails for unknown images" do
        expect(render_page_content("%carousel(123456)%")).to eq <<~HTML.chomp
          <em class="text-danger">(unknown template function: carousel(123456))</em>
        HTML
      end
    end
  end
end
