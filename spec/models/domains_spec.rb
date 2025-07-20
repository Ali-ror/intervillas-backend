require "rails_helper"

RSpec.describe Domain do
  subject(:domain) { build :domain }

  it { is_expected.to validate_presence_of    :name }
  it { is_expected.to validate_uniqueness_of  :name }
  it { is_expected.to validate_presence_of    :brand_name }
  it { is_expected.to validate_presence_of    :theme }

  describe "#partial_names" do
    # valid partial names
    Pathname.glob(Rails.root.join("app/views/home/dynamic/_*.html.haml")).each do |partial|
      partial_name = partial.basename.to_s.split(".").first[1..-1]

      it "allows #{partial_name}" do
        domain.partials = [partial_name]
        expect(domain).to be_valid
        expect(domain.partials).to eq [partial_name]
      end
    end

    # invalid partial names are silently ignored
    [["foo.bar"], [""], nil].each do |names|
      it "ignores #{names.inspect}" do
        domain.partials = names
        expect(domain).to be_valid
        expect(domain.partials).to eq []
      end
    end
  end

  describe "#content_md" do
    subject(:domain) { create :domain, de_content_md: "abrakadabra", en_content_md: "abracadabra" }

    %w[de en].each do |locale|
      it "updating #{locale} content updates record" do
        expect {
          tr = domain.translations.find_by(locale: locale)
          tr.update! content_md: "hallo welt!"
        }.to change(domain, :updated_at)
      end
    end
  end
end
