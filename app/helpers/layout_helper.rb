module LayoutHelper
  def active_class(obj)
    # Request-Pfad enthält Pfad des übergebenen Objekts
    # z.Bsp: /admin/boats/2/occupancies enthält boats/2/
    # /admin/villas/35-villa-riverside/occupancies enthält
    # villas/35-villa-riverside/
    obj_path = [
      "",
      model_name_from_record_or_class(obj).route_key,
      record_key_for_dom_id(obj),
    ].join "/"

    "active" if request.path.include?(obj_path)
  end

  def list_link_to(anchor, href, icon: nil, active: nil, **rest)
    anchor = fa(:fw, icon, text: anchor) if icon
    content_tag :li, link_to(anchor, href, rest), class: nav_li_class(href, active: active)
  end

  def nav_li_class(*hrefs, active: nil)
    active ||= hrefs
      .map  { |href| href.index("?") ? URI.parse(href).path : href } # discard query
      .any? { |path| request.path.end_with? path }

    "active" if active
  end

  def dt_dd_for(resource, attribute, *helper) # rubocop:disable Metrics/CyclomaticComplexity
    a       = attribute.to_sym
    content = resource.send(a)
    content = yield content if block_given?
    content = I18n.t("helper.no-content") if content.to_s.empty?

    if helper.size > 0
      m       = helper.shift
      content = if m == :l
        I18n.send m, content, *helper # I18n.l(content, *args)
      else
        send m, content, *helper # e.g. simple_format(content, *args)
      end
    end

    # convert bool to check mark
    content = case content
    when true  then fa :check, class: "text-success", text: I18n.t("helper.yes")
    when false then fa :times, class: "text-danger", text: I18n.t("helper.no")
    else content
    end

    caption_recv = resource.respond_to?(:human_attribute_name) ? resource : resource.class
    content_tag(:dt, caption_recv.human_attribute_name(a)) + content_tag(:dd, content)
  end

  def menu_invoicables_counter
    menu_item_with_counter "invoicables", Billing do
      Inquiry.invoicable.count
    end
  end

  def menu_reviews_counter
    menu_item_with_counter "reviews", Review do
      Review.undeleted.unpublished.with_text.with_rating.count
    end
  end

  def menu_payments_counter
    menu_item_with_counter "payments", Payment do
      Payment::View.overdue.count
    end
  end

  def menu_item_with_counter(name, model)
    item = I18n.t name, scope: "shared.admin_menu"

    span = if block_given? && can?(:index, model) && (count = yield) > 0
      content_tag :span, count, class: "badge", title: I18n.t("#{name}_counter", scope: "shared.admin_menu")
    end

    [item, span].compact.join(" ").html_safe # rubocop:disable Rails/OutputSafety
  end

  def confirmation_subsection(title, **opts, &block)
    opts[:title] = title
    render layout: "bookings/confirmation_subsection", locals: opts, &block
  end

  def preload_slide(slide)
    ext     = ImgProxy.guess_preferred_image_format(request.headers["Accept"])
    type    = ext == "jpg" ? "image/jpeg" : "image/#{ext}"
    preload = []

    Slider.each do |preset, next_smaller_size, width|
      media = [
        ("(min-width: #{next_smaller_size}px)" if preset != :slide_sm),
        ("(max-width: #{width}px)"             if preset != :slide_xl),
      ].compact.join(" and ")

      link = tag.link(
        as:    "image",
        type:  type,
        rel:   "preload",
        href:  media_url(slide, preset: preset),
        media: media,
      )

      preload.push link
    end

    preload.join("\n").html_safe # rubocop:disable Rails/OutputSafety
  end

  def slider_sources_for(slide)
    sources = [tag.img(src: media_url(slide, preset: :slide_md))]

    src_set = Slider.map { |preset, _, width|
      url = media_url(slide, preset: preset)
      url << " #{width}w" if preset != :slide_xl
      url
    }

    sources.push tag.source srcset: src_set.join(", ")
    sources.join("\n").html_safe # rubocop:disable Rails/OutputSafety
  end

  def hero_slides(domain)
    domain.slides.active.map { |slide|
      Slider.map { |preset, _, width|
        { width: width, src: media_url(slide, preset: preset) }
      }
    }.to_json
  end

  # @api private
  module Slider
    SIZES = {
      slide_xl: [1440, 1920],
      slide_lg: [1080, 1440],
      slide_md: [768, 1080],
      slide_sm: [0, 768],
    }.freeze

    def self.each
      SIZES.each do |preset, sizes|
        yield preset, *sizes
      end
    end

    def self.map
      SIZES.map do |preset, sizes|
        yield preset, *sizes
      end
    end
  end
end
