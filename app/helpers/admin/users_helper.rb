module Admin::UsersHelper

  def access_level_label(level)
    lvl = User::ACCESS_LEVEL.keys.reverse.index(level)
    lbl = %w[ default default success success danger ][lvl]

    content_tag(:span, lvl, class: ["label", "label-#{lbl}"]) + " ".html_safe +
      h(t(level, scope: "admin.users.access_level.title"))
  end

  def user_access_level_collection
    User::ACCESS_LEVEL.keys.map {|level|
      [I18n.t(level, scope: "admin.users.access_level.oneline"), level]
    }
  end

  def contact_list_for_user(user)
    selected = user.contact_ids

    Contact.all.map{|c| [c.to_s, c.id] }.sort{|(as,ai), (bs,bi)|
      case [selected.include?(ai), selected.include?(bi)]
        when [true, false] then -1
        when [false, true] then 1
        else as <=> bs
      end
    }
  end

end
