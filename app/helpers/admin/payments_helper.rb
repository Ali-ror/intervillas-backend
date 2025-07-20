module Admin
  module PaymentsHelper
    def payment_scopes_for_select
      (Payment::SCOPES - ["paypal"]).map { |sc|
        [t(sc, scope: "payments.scope"), sc]
      }
    end

    def li_payment_tab(action, href, controller: "payments")
      tag.li class: ("active" if controller_action == "#{controller}##{action}") do
        link_to payment_tab_name(action), href, title: payment_tab_title(action), class: "px-3"
      end
    end

    def payment_tab_name(action_name_override = nil)
      _payment_tab :name, action_name_override
    end

    def payment_tab_title(action_name_override = nil)
      _payment_tab :title, action_name_override
    end

    def _payment_tab(value, action_name_override = nil)
      name = action_name_override || action_name
      if name == "balance" && params[:year]
        t value, scope: "admin.payments.tabs.balance_for", year: params[:year]
      else
        t value, scope: "admin.payments.tabs.#{name}"
      end
    end
  end
end
