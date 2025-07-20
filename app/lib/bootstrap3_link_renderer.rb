require "will_paginate"
require "will_paginate/view_helpers/action_view"

class Bootstrap3LinkRenderer < WillPaginate::ActionView::LinkRenderer
  def html_container(html)
    tag :ul, html, class: "pagination"
  end

  def previous_or_next_page(page, text, classname, aria_label = nil)
    link_text = classname == "next_page" ? "&raquo;" : "&laquo;"

    if page
      link = link(link_text, page)
      tag(:li, link, "aria-label" => aria_label)
    else
      span = tag(:span, link_text)
      tag(:li, span, class: "disabled", "aria-label" => aria_label)
    end
  end

  def page_number(page)
    if page == current_page
      span = tag(:span, page)
      tag(:li, span, class: "disabled")
    else
      link = link(page, page, rel: rel_value(page))
      tag(:li, link)
    end
  end

  def gap
    span = tag(:span, "&hellip;")
    tag(:li, span, class: "disabled")
  end
end
