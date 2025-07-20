#
# Helper für ApplicationMailer und dessen Subklassen.
#
module MailerHelper
  BUTTON_LIKE_LINK_STYLE = {
    margin:               "5px auto",
    display:              "inline-block",
    "background-color" => "#50878e",
    "text-align"       => :center,
    padding:              "5px",
  }.map { |k, v| "#{k}:#{v}" }.join(";").freeze

  def mail_button_link_to(href)
    content_tag :div, style: BUTTON_LIKE_LINK_STYLE do
      link_to(href, style: "color:#fff") { yield }
    end
  end
end
