module Admin::MessagesHelper
  def embed_message_form(message, type=nil, preview: true, text: true)
    type ||= [*message].last.template

    render "messages/form_embedded",
      message:  message,
      preview:  preview,
      text:     !!text,
      type:     type.to_s
  end

  def embed_email_iframe(mail)
    mail_content = (mail.multipart? ? mail.parts.first.decoded : mail.decoded)

    opts = {
      width:        "100%",
      height:       600, # wird von JS angepasst
      frameborder:  0,
      srcdoc:       mail_content.html_safe
    }
    content_tag :iframe, "", opts
  end
end
