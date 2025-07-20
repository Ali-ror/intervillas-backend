module DynamicAssociationHelper
  def link_to_add_association(anchor_text, association_name, template:, size: :xs, style: :default)
    icon  = fa :plus, text: anchor_text
    css   = "btn btn-#{style} btn-#{size}"
    data  = {
      toggle:       "add-association",
      association:  association_name,
      template:     template,
    }

    content_tag :button, icon, type: :button, class: css, data: data
  end

  def link_to_remove_association(anchor_text, size: :xs, style: :warning)
    icon  = fa :trash, text: anchor_text
    css   = "btn btn-#{style} btn-#{size}"
    data  = { toggle: "remove-association" }

    content_tag :button, icon, type: :button, class: css, data: data
  end
end
