require "rails_helper"

RSpec.describe Snippet do
  context "validations" do
    # for validate_uniqueness_of to work
    subject { build :snippet }

    before { create :snippet }

    it { is_expected.to validate_uniqueness_of :key }
    it { is_expected.to validate_presence_of :key }
    it { is_expected.to validate_presence_of :title }
  end

  describe "content" do
    subject { Snippet.new key: "test-key", title: "test-title", de_content_md: "# de-md", en_content_md: "# en-md" }

    it "generates HTML from Markdown upon create" do
      expect(subject.de_content_html).to be_nil
      expect(subject.en_content_html).to be_nil
      subject.save!
      expect(subject.de_content_html).to eq "<h1>de-md</h1>"
      expect(subject.en_content_html).to eq "<h1>en-md</h1>"
    end

    it "updates HTML when updating the record" do
      subject.save!
      subject.de_content_md = "## de-md"
      subject.en_content_md = "## en-md"
      subject.save!
      expect(subject.de_content_html).to eq "<h2>de-md</h2>"
      expect(subject.en_content_html).to eq "<h2>en-md</h2>"
    end
  end
end
