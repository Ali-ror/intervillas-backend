module ContactsHelper
  def contact_form_tag
    props = {
      id:           "contact",
      url:          api_contacts_path,
      sitekey:      (Recaptcha.configuration.site_key if require_recaptcha?),
      "villa-id" => params[:villa_id] || (params[:id] if controller_name == "villas"),
    }.compact

    content_tag "contact-form", nil, props
  end
end
