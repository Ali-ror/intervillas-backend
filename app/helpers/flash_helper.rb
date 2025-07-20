module FlashHelper
  FLASH_MAPPING = {
    # from flash type to [icon name, bootstrap class]
    "alert"           => [:times_circle,          "alert fa-alert alert-danger"],
    "error"           => [:times_circle,          "alert fa-alert alert-danger"],
    "info"            => [:info_circle,           "alert fa-alert alert-info"],
    "notice"          => [:info_circle,           "alert fa-alert alert-info"],
    "success"         => [:check_circle,          "alert fa-alert alert-success"],
    "warning"         => [:exclamation_triangle,  "alert fa-alert alert-warning"],
    "pw_expiry"       => [:key,                   "alert fa-alert alert-warning"],

    # or to `false`, if key should be skipped
    "recaptcha_error" => false,
    "timedout"        => false,
  }.freeze

  DEFAULT_FLASH = FLASH_MAPPING["info"]

  def flash_messages(wrapper_class: nil)
    out = []
    flash.each do |type, message|
      icon, alert = FLASH_MAPPING.fetch(type, DEFAULT_FLASH)
      next if icon == false

      message = [fa(icon), " ", h(message), " "]
      if type == "pw_expiry" && !current_page?(admin_edit_user_registration_path)
        link = link_to t("devise.passwords.update"), admin_edit_user_registration_path, class: "alert-link"
        message << link
      end
      message << %(<a class="close" data-dismiss="alert">×</a>).html_safe

      out << content_tag(:div, message.join.html_safe, class: alert) # rubocop:disable Rails/OutputSafety
    end

    return if out.empty?

    wrapper_class ||= "hidden-print mt-4"
    content_tag(:div, out.join.html_safe, class: wrapper_class) # rubocop:disable Rails/OutputSafety
  end
end
