module Admin::ClearingsHelper
  def button_to_deliver_admin_clearing(owner_id, currency:, icon:, text:)
    button_to deliver_admin_clearing_path(owner_id),
      class:  "btn btn-xxs btn-default",
      params: { month: clearing_date.month, year: clearing_date.year, currency: currency },
      data:   { disable_with: t(:wait) } do
      fa icon, text: text
    end
  end
end
