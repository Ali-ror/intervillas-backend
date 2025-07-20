module PagesHelper
  def render_page_content(page)
    return render("pages/#{page.template_path}") if page.template_path?
    return if page.content.blank?

    PageTemplateFuncs.apply_to(self, page.content).html_safe # rubocop:disable Rails/OutputSafety
  end

  def li_link_to_page(name, &block)
    pg = Page.joins(:route).on_domain(current_domain).find_by(routes: { name: name })
    return unless pg && pg.name.present? # Wenn Titel für Sprache nicht gesetzt, dann nicht anzeigen

    tag.li do
      if block_given?
        link_to "/#{pg.route.path}", &block
      else
        link_to(pg.name, "/#{pg.route.path}")
      end
    end
  end

  def link_to_satellite(domain)
    labels = [
      domain.multilingual? && I18n.locale != :de ? I18n.locale : "www",
      ("staging" if Rails.env.staging?),
      domain.name,
    ]

    labels[-1] = "#{domain.id}.self.digineo.lan" if Rails.env.development?

    domain_hostname = labels.compact.join(".")
    link_to domain.brand_name, root_url(host: domain_hostname)
  end

  JSON_LD_BASE_ARTICLE = {
    "@context"         => "https://schema.org",
    "@type"            => "NewsArticle",
    "mainEntityOfPage" => {
      "@type" => "WebPage",
      "@id"   => "https://google.com/article",
    },
  }.freeze

  def page_metadata_json(page)
    meta = JSON_LD_BASE_ARTICLE.merge \
      "datePublished" => page.published_at&.iso8601,
      "dateModified"  => page.modified_at&.iso8601
    meta.compact.to_json
  end
end
