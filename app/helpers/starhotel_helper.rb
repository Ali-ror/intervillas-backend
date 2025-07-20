module StarhotelHelper
  def calendar_field_tag(name, value, options = {})
    tf_options = { class: "form-control ", readonly: true }
    tf_options[:class] << options.delete(:class)
    tf_options.merge! options

    text_field_tag name, value, tf_options
  end

  # List CSS class names, weighted for random choice. Keep in sync with
  # `app/javascripts/stylesheets/application/_page-heading.sass`.
  # TODO: improve memory-performance
  PAGE_HEADER_CHOICES = {
    "dock"    => 3,
    "sundeck" => 2,
    "pool"    => 1,
  }.flat_map { |name, w| [name] * w }

  def page_header(&block)
    content_tag(:section, class: "page-heading") {
      content_tag :div, class: ["page-heading-bg", PAGE_HEADER_CHOICES.sample] do
        content_tag :div, class: "color-overlay" do
          content_tag :div, class: "container", &block
        end
      end
    } + flash_messages(wrapper_class: "container hidden-print")
  end

  def breadcrumb
    @breadcrumb ||= Breadcrumb.new(self)
  end

  def full_width_section(&block)
    content_tag :section do
      content_tag :div, class: "container" do
        content_tag :div, class: "row" do
          content_tag :div, class: "col-md-12", &block
        end
      end
    end
  end

  def accordion_panel(heading, add_to_id = nil, options = {}, &block)
    dom_id = [heading.parameterize, add_to_id].join "-"
    render layout: "/shared/accordion_panel", locals: { heading: heading, dom_id: dom_id, options: options }, &block
  end

  def panel(heading, style: "primary", &block)
    render layout: "/shared/panel", locals: { heading: heading, style: style }, &block
  end
end
