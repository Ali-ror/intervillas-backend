module SnippetHelper
  def render_snippet(key, wrap_in: nil)
    content = Snippet.content_for(key)
    return if content.blank?

    content_tag :div, content.html_safe, # rubocop:disable Rails/OutputSafety
      id:    "snippet-#{key}",
      class: wrap_in
  end
end
