class ContactMailer < ApplicationMailer
  layout "contact_mailer"

  def contact_mail(request)
    @request = request

    mail \
      to:       "info@intervillas-florida.com",
      from:     "noreply@intervillas-florida.com",
      reply_to: request.email,
      subject:  I18n.t("contact_mailer.contact_mail.subject")
  end
end
