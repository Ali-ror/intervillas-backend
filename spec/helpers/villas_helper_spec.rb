require "rails_helper"

RSpec.describe VillasHelper do
  describe "#insert_yt_link" do
    shared_examples "YouTube-Link einfügen" do
      subject(:capybara) { Capybara.string(formatted_html) }

      context "URL in eigener Zeile" do
        let(:formatted_html) {
          helper.insert_yt_link(<<~VILLA_DESC, "Villa Name")
            Stuff ...
            #{url}
            Die Villa Yada Yada bietet einen großzügigen Aussenpool und
            eine moderne Grillanlage.
          VILLA_DESC
        }

        it "fügt Button ein" do
          expect(capybara).to have_link("Villa Name bei YouTube", href: url) do |link_el|
            link_el["class"].include? "btn"
          end
        end
      end

      context "URL im Textfluss" do
        let(:formatted_html) {
          helper.insert_yt_link(<<~VILLA_DESC, "Villa Name")
            Stuff #{url} Die Villa Yada Yada bietet einen großzügigen Aussenpool und
            eine moderne Grillanlage.
          VILLA_DESC
        }

        it "fügt Link ein" do
          expect(capybara).to have_link(url, href: url) do |link_el|
            link_el["class"].blank?
          end
        end
      end
    end

    context "youtu.be" do
      let(:url) { "https://youtu.be/VIDEOID" }

      include_examples "YouTube-Link einfügen"
    end

    context "youtube.com" do
      let(:url) { "https://youtube.com/watch?v=VIDEOID" }

      include_examples "YouTube-Link einfügen"
    end

    context "www.youtube.com" do
      let(:url) { "https://www.youtube.com/watch?v=VIDEOID" }

      include_examples "YouTube-Link einfügen"
    end

    context "www.youtube.com mit zusätzlichem Parameter" do
      let(:url) { "https://www.youtube.com/watch?v=VIDEOID&feature=youtu.be" }

      include_examples "YouTube-Link einfügen"
    end
  end
end
