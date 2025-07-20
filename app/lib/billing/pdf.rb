#
# Wrapper um Texd
#
# Erwartet eine Billing::{Owner, Tenant}-Instanz und einen Datei-Namen.
#
Billing::Pdf = Struct.new(:billing, :id_string) do
  def file_name
    @file_name ||= Rails.root.join("data/billings", id_string).sub_ext(".pdf")
  end

  def save(force: false)
    render! if force_render?(force)
    file_name
  end

  def force_render?(cond)
    return true if cond == true || !file_name.exist?
    return cond.call(file_name) if cond.respond_to?(:call)

    false
  end

  def render!
    blob = Texd.render(
      layout:   "layouts/billing",
      template: template.template,
      locals:   template.locals,
    )

    file_name.dirname.mkpath
    file_name.open("wb") { |f| f << blob }
  end

  def template
    @template ||= wrapper_class.new billing
  end

  def delete
    file_name.delete if file_name.exist?
  rescue SystemCallError
    # ignore ENOENT etc.
  end

  def wrapper_class
    case billing
    when Billing::Tenant  then Billing::Template::Tenant
    when Billing::Owner   then Billing::Template::Owner
    else raise ArgumentError, "expected Billing::Tenant or Billing::Owner"
    end
  end
end
