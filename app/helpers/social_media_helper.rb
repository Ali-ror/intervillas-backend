module SocialMediaHelper
  FACEBOOK_PAGE = "https://www.facebook.com/pages/Intervillas-Florida/172562022787869".freeze

  SOCIAL_MEDIA_LINKS = {
    facebook:  ["Facebook", FACEBOOK_PAGE, :facebook_square],
    whatsapp:  ["WhatsApp", "https://wa.me/12396037627"],
    instagram: ["Instagram", "https://instagram.com/intervillasflorida"],
  }.freeze

  def social_link_to(network)
    title, url, icon = SOCIAL_MEDIA_LINKS[network]
    return unless title && url

    link_to url, class: "contact-nav-item", target: :_blank, rel: "noopener" do
      fa(:fw, icon || network) + tag.span(title)
    end
  end
end
