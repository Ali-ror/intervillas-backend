require "set"

module RequestDomain
  class << self
    def resolve(domain)
      labels = domain.split(".") # www.staging.iv.com => %w[www staging iv com]
      scope  = Domain.includes(:translations)

      if Rails.env.development?
        return scope.find(labels[0]) if labels[0] =~ /^\d+$/ # domain == 1.local.digineo.de
        return scope.find(labels[1]) if labels[1] =~ /^\d+/  # domain == en.2.local.digineo.de
      end

      # %w[www staging iv com] => %w[www.staging.iv.com staging.iv.com iv.com]
      # (no "com" entry)
      suffixes = 1.upto(labels.size - 2).each_with_object([domain]) do |i, list|
        list.push labels[i..-1].join(".")
      end

      scope.find_by(name: suffixes) || default
    end

    def default
      Domain.includes(:translations).find_by!(default: true)
    end
  end

  # ControllerExtension provides a current_domain helper. It is meant
  # to be mixed into your ApplicationController.
  module ControllerExtension
    extend ActiveSupport::Concern

    included do
      helper_method :current_domain
      helper SEOSpamHelper
    end

    def current_domain
      @current_domain ||= RequestDomain.resolve(request.host)
    end

    def with_current_domain(scope)
      scope.on_domain(current_domain)
    end
  end

  module SEOSpamHelper
    # Soll produzieren:
    #
    # für {www,en}.intervillas-florida.com (default, interlink, multilingual)
    #   <link rel="alternate" href="http://www.intervillas-florida.com/" hreflang="de" />
    #   <link rel="alternate" href="http://en.intervillas-florida.com/" hreflang="en" />
    #
    # für www.cape-coral-ferienhaeuser.com (!default, !interlink, multilingual)
    #   <link rel="canonical" href="http://www.intervillas-florida.com/" />
    #   <link rel="alternate" href="http://www.intervillas-florida.com/" hreflang="de" />
    #   <link rel="alternate" href="http://en.intervillas-florida.com/" hreflang="en" />
    #
    # für en.cape-coral-ferienhaeuser.com (!default, !interlink, multilingual)
    #   <link rel="canonical" href="http://en.intervillas-florida.com/" />
    #   <link rel="alternate" href="http://www.intervillas-florida.com/" hreflang="de" />
    #   <link rel="alternate" href="http://en.intervillas-florida.com/" hreflang="en" />
    #
    # für www.villa-capecoral-mieten.de (!default, interlink, !multilingual)
    #   <link rel="alternate" href="http://www.villa-capecoral-mieten.de/" hreflang="de" />
    #   <link rel="alternate" href="http://en.intervillas-florida.com/" hreflang="en" />
    #
    # siehe support#163
    def seo_spam_links
      [
        canonical_link_tag,
        alternate_link_tag(:de, "www"),
        alternate_link_tag(:en, "en"),
        alternate_link_tag("x-default", "en"),
      ].compact.join("\n").html_safe # rubocop:disable Rails/OutputSafety
    end

    private

    def canonical_link_tag
      # nicht auf Haupt-Domain und Satelliten-Seiten
      return if current_domain == __default_domain
      return if current_domain.interlink?

      # nicht auf Content-Seiten (/admin/pages), wenn diese nur auf einer Domain geschaltet ist
      return if params[:controller] == "admin/pages" && params[:action] == "show" && page.domains.count == 1

      subdomain = request.subdomains[0]
      canonical = [
        (subdomain if %w[www en].include?(subdomain)),
        __default_domain.name,
      ].compact.join(".")
      href      = url_for host: canonical, only_path: false
      tag.link rel: "canonical", href: href
    end

    def alternate_link_tag(lang, subdomain)
      domain = if current_domain.language_code == lang
        current_domain.name
      else
        __default_domain.name
      end

      host = [subdomain, domain].compact.join(".")
      href = url_for host: host, only_path: false
      tag.link rel: "alternate", href: href, hreflang: lang
    end

    def __default_domain
      @__default_domain ||= RequestDomain.default
    end
  end
end
