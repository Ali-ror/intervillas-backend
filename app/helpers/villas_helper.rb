module VillasHelper
  def link_to_filter(filter_selector, description)
    link_to description, "#", data: { filter: filter_selector }
  end

  YT_RE = %r{(https?://(?:(?:www\.)?youtube.com/watch\?v=|youtu.be/)\w+\S*)}.freeze

  YT_BLOCK        = /^\s*#{YT_RE}\s*$/o.freeze
  YT_BLOCK_INSERT = <<~HTML.strip.freeze
    <a class="btn btn-primary" target="_blank" href="%<href>s">
      <i class="fa fa-fw fa-play"></i> %<villa_name>s bei YouTube
    </a>
  HTML

  YT_INLINE        = /\s#{YT_RE}\s/o.freeze
  YT_INLINE_INSERT = <<~HTML.strip.freeze
    <a target="_blank" href="%<href>s">%<href>s</a>
  HTML

  def insert_yt_link(description, villa_name)
    desc = description.to_s # create new String, also coerces Description models
    return if desc.blank?

    desc.gsub! YT_BLOCK do |_match|
      "\n" << format(YT_BLOCK_INSERT, href: Regexp.last_match(1), villa_name: villa_name) << "\n"
    end

    desc.gsub! YT_INLINE do |_match|
      " " << format(YT_INLINE_INSERT, href: Regexp.last_match(1)) << " "
    end

    desc
  end

  SQM_TO_SQFT_FACTOR = 1_562_500.0 / 145_161 # m² → ft²

  def living_area(villa)
    area = villa.living_area
    return area if I18n.locale == :de # m²

    (area * SQM_TO_SQFT_FACTOR).floor # ft²
  end
end
