module ReviewsHelper
  # weil ActionView::Helpers::TextHelper#simple_format *zu* einfach ist
  #
  # Wenn `n_words > 0`, dann wird der Text mit zusätzlichem Markup versehen,
  # um die ersten `n_words` Worte vom Rest abzutrennen (z.B. um
  # den Rest auszublenden). Wenn der Test aus weniger als `n_words+10` Worten
  # besteht, wird keine Trennung durchgeführt.
  #
  # `parts_connector` wird benutzt um die ersten `n_words` Worte mit dem
  # Rest zu verbinden (kann z.B. ein `link_to 'weiterlesen', ...` sein.)
  def format_review(review_or_message, n_words = nil, parts_connector = nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength,
    text = case review_or_message
    when Review then review_or_message.text
    when String then review_or_message
    else raise TypeError, "wrong argument: review_or_message must either be Review or String instance"
    end

    # hier noch relativ ähnlich zu #simple_format
    start_tag = "<p>"
    text      = sanitize(text.to_s.gsub(/ +/, " "), tags: [], attributes: []).to_str
    text.gsub!(/\r\n?/, "\n")               # \r\n and \r -> \n
    text.gsub!(/\n\n+/, "</p>#{start_tag}") # 2+ newline  -> paragraph
    text.insert 0, start_tag
    text << "</p>"

    # die ersten n Worte vom Rest abtrennen (via Markup)
    if n_words.is_a?(Integer)
      # nur trennen, wenn der Split nicht kurz vorm Ende passieren würde
      unless n_words > 0 && (split = text.split " ").size > n_words + 10
        return content_tag :div, text.html_safe, class: "split-text" # rubocop:disable Rails/OutputSafety
      end

      # Text in "pre"/"post" trennen
      pre = split[0...n_words].join(" ")
      pre.gsub!(/\A<p>/,       "<p><span class='split-text-pre'>")
      pre.gsub!(%r{</p><p>},   "</span></p><p><span class='split-text-pre'>")
      pre.gsub!(%r{(</p>)?\z}) do
        rest = $1.presence # rubocop:disable Style/PerlBackrefs
        "<span class='split-text-cont'>&hellip;</span> #{parts_connector}</span>#{rest}"
      end

      post = split[n_words..-1].join(" ")
      post.gsub!(/\A<p>/,       "<p class='split-text-post'>")
      post.gsub!(/\A(?!<p>)/,   " <span class='split-text-post'>")
      post.gsub!(%r{</p><p>},   "</span></p><p class='split-text-post'><span class='split-text-post'>")
      post.gsub!(%r{</p>\z},    "</span></p>")

      return content_tag :div, [pre, post].join(" ").html_safe, class: "split-text" # rubocop:disable Rails/OutputSafety
    end

    text.html_safe # rubocop:disable Rails/OutputSafety
  end

  # baut Markup für eine Vue-Komponente
  def toggle_active_for_review(review)
    props = {
      url:               toggle_publish_admin_review_path(review),
      ":disabled"     => review.deleted_at? || review.incomplete? || nil,
      ":active"       => review.published_at? || nil,
      "disabled-text" => "nein",
      "active-text"   => "ja",
      "inactive-text" => "nein",
    }.compact

    content_tag "toggle-active", nil, props
  end

  def toggle_review_state(state, review)
    url, active, disabled = case state
    when :publish
      [
        toggle_publish_admin_review_path(review),
        review.published_at?,
        review.deleted_at? || review.incomplete?,
      ]
    when :archive
      [
        toggle_archive_admin_review_path(review),
        review.deleted_at?,
        false,
      ]
    else
      raise ArgumentError, "unknown attribute: #{state.inspect}, expected :publish or :archive"
    end

    props = {
      url:               url,
      ":disabled"     => disabled.presence,
      ":active"       => active.presence,
      "disabled-text" => "nein",
      "active-text"   => "ja",
      "inactive-text" => "nein",
    }.compact

    content_tag "toggle-active", nil, props
  end
end
