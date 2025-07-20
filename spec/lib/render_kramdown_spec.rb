require "rails_helper"

RSpec.describe RenderKramdown do
  subject { RenderKramdown.new(content) }

  let(:content) { <<~MARKDOWN }
    ## section 1
    text 1

    ### subsection 1.1
    text 1.1

    ## section 2
    text 2
  MARKDOWN

  let(:html) { <<~HTML.strip }
    <h2>section 1</h2>
    <p>text 1</p>

    <h3>subsection 1.1</h3>
    <p>text 1.1</p>

    <h2>section 2</h2>
    <p>text 2</p>
  HTML

  let(:section_1) { <<~HTML.strip }
    <h2>section 1</h2>
    <p>text 1</p>

    <h3>subsection 1.1</h3>
    <p>text 1.1</p>
  HTML

  let(:section_2) { <<~HTML.strip }
    <h2>section 2</h2>
    <p>text 2</p>
  HTML

  it "renders to html" do
    expect(subject.to_html).to eq html
  end

  it "renders seo sections" do
    expect(subject.seo_sections).to eq [section_1, section_2]
  end

  context "marker substitution" do
    let(:content) { <<~MARKDOWN }
      # foo %next_vacation_year% bar

      %next_vacation_year% %typo_vacation_year% %next_vacation_year%!
    MARKDOWN

    let(:year) {
      now = Time.current
      now.month < 6 ? now.year : now.year + 1
    }

    let(:html) { <<~HTML.strip }
      <h1>foo #{year} bar</h1>

      <p>#{year} %typo_vacation_year% #{year}!</p>
    HTML

    it "renders to html" do
      expect(subject.to_html).to eq html
    end
  end

  context "weird content" do
    let(:content) { <<~MARKDOWN }
      ## subsection -1
      text -1

      # section 2
      text 2

      ## subsection 2.1
      text 2.1
    MARKDOWN

    let(:section_1) { <<~HTML.strip }
      <h2>subsection -1</h2>
      <p>text -1</p>
    HTML

    let(:section_2) { <<~HTML.strip }
      <h1>section 2</h1>
      <p>text 2</p>

      <h2>subsection 2.1</h2>
      <p>text 2.1</p>
    HTML

    it "renders seo sections" do
      expect(subject.seo_sections).to eq [section_1, section_2]
    end
  end
end
