require "kramdown"

class RenderKramdown < Struct.new(:content)
  MARKERS = {
    "%next_vacation_year%" => ->{
      now = Time.current
      now.month < 6 ? now.year : now.year+1
    }
  }.freeze
  private_constant :MARKERS

  # renders the content into a single HTML blob
  def to_html
    render content.to_s
  end

  # splits the content at header markers (`#`), and renders each section
  # individually
  def seo_sections
    top_heading_level = content.scan(/^#+/).sort.first # "#" <=> "##" == -1
    return [render(content)] if top_heading_level.nil?

    sections = content.split(/^#{top_heading_level}(?!#)/)
    start, skip = 0, true
    if sections[0] == ""
      start, skip = 1, false
    end

    sections[start..-1].map do |sec|
      if skip
        skip = false
      else
        sec = top_heading_level + sec
      end
      render(sec)
    end
  end

  private

  def render(s)
    s = replace_markers(s)
    Kramdown::Document.new(s, options).to_html.strip
  end

  def options
    quotes = if I18n.locale == :de
      # swiss quotation marks: <single> «double»
      ["lsaquo", "rsaquo", "laquo", "raquo"]
    else
      # english quotation marks: ‘single’ “double”
      ["lsquo", "rsquo", "ldquo", "rdquo"]
    end

    {
      auto_ids:           false,
      enable_coderay:     false,
      syntax_highlighter: nil,
      smart_quotes:       quotes,
    }
  end

  def replace_markers(s)
    s.gsub(/%\w+%/) {|mark|
      MARKERS.key?(mark) ? MARKERS[mark].call : mark
    }
  end
end
