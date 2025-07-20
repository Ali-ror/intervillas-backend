# NOTE: Changes here require a server restart.

require "img_proxy/preset"
require "img_proxy/middleware"
require "img_proxy/test_stub"

module ImgProxy
  # Variant presets. Use `media_url(..., preset: name)` to select `PRESETS[name]`.
  # The values are processing options for ImgProxy. See their documentation at:
  # https://docs.imgproxy.net/generating_the_url?id=processing-options.
  #
  # NOTE: When changing preset values, you'll need to purge `data/variants/**/name@*.*`,
  # otherwise the changes won't effect cached variants.
  # rubocop:disable Layout/LineLength
  PRESETS = [
    Preset.new("full",          fit:  { w: 1920 },         watermark: { pos: :so,   opacity: 0.2, scale: 0.25 }),
    Preset.new("teaser",        fill: { w: 356,  h: 228 }, watermark: { pos: :soea, opacity: 0.3, scale: 0.3, x: 8, y: 4 }),
    Preset.new("carousel",      fill: { w: 750,  h: 481 }, watermark: { pos: :so,   opacity: 0.2, scale: 0.25 }),
    Preset.new("gallery_xl",    fit:  { w: 1920 },         watermark: { pos: :so,   opacity: 0.2, scale: 0.2 }),
    Preset.new("gallery_lg",    fit:  { w: 1440 },         watermark: { pos: :so,   opacity: 0.2, scale: 0.25 }),
    Preset.new("gallery_md",    fit:  { w: 1080 },         watermark: { pos: :so,   opacity: 0.2, scale: 0.3 }),
    Preset.new("carousel_sm",   fill: { w: 80,   h: 80 }),
    Preset.new("admin_thumb",   fill: { w: 121,  h: 80 }),
    Preset.new("video_preview", fit:  { w: 1140, h: 500 }),        # for Media::Video
    Preset.new("tour_preview",  fit:  { w: 300,  h: 150 }),        # for Media::Pannellum
    Preset.new("tour_lg",       fill: { w: 4000, h: 2000 }),       # for Media::Pannellum
    Preset.new("slide_xl",      fit:  { w: 1920 }),                # for Media::Slide
    Preset.new("slide_lg",      fit:  { w: 1440 }),                # for Media::Slide
    Preset.new("slide_md",      fit:  { w: 1080 }),                # for Media::Slide
    Preset.new("slide_sm",      fit:  { w: 768 }),                 # for Media::Slide
    Preset.new("mybookingpal",  fit:  { w: 1600 }, format: "jpg"), # for MyBookingPal exports
  ].index_by(&:name).freeze
  # rubocop:enable Layout/LineLength

  # keep in sync with SUPPORTED_DPR_VALUES in app/javascript/frontend/RetinaImage.vue
  SUPPORTED_DPR_VALUES = [1, 2].freeze

  # @api private
  def self.verifier
    @verifier ||= begin
      secret = "imgproxy.#{Rails.application.secret_key_base}"
      ActiveSupport::MessageVerifier.new secret,
        digest:     :SHA256, # rubocop:disable Naming/VariableNumber
        serializer: YAML
    end
  end

  def self.generate_checksum(blob_id, preset_name, file_name)
    verifier.generate([blob_id, PRESETS.fetch(preset_name.to_s).to_s, file_name]).split("--")[1].slice(-16..-1)
  end

  def self.verify_checksum(blob_id, preset_name, file_name, checksum)
    expected = generate_checksum(blob_id, preset_name, file_name)
    ActiveSupport::SecurityUtils.secure_compare expected, checksum
  end

  # @api private
  def self.guess_preferred_image_format(accept)
    # Accept: image/webp, image/avif;q=0.9, */*;q=0.8  =>  webp
    # Accept: */*                                      =>  jpg
    fmt, = (accept.to_s.presence || "*/*").split(",").map { |e|
      parse_accept_header_entry(e)
    }.compact.min_by(&:second)

    return "webp" if fmt == "image/webp"
    return "avif" if fmt == "image/avif"

    "jpg"
  end

  # @api private
  def self.extract_format_from_preset(preset_name)
    PRESETS.fetch(preset_name.to_s).fetch(:format, nil)
  end

  # @api private
  def self.parse_accept_header_entry(fmt)
    mime, qual = fmt.strip.split(";")
    return unless mime.start_with?("image/")
    return [mime, 1.0] unless qual

    qual = CGI.parse(qual).fetch("q", []).first || "1.0"
    [mime, qual.to_f]
  end
end
