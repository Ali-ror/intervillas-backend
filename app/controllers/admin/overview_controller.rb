class Admin::OverviewController < AdminController
  layout "admin_bootstrap"

  helper_method :item_utilization

  expose(:villas) do
    current_user.villas.includes(:route).order(active: :desc, name: :asc)
  end
  expose(:boats)  { current_user.boats.order(hidden: :asc, id: :asc) }
  expose(:cables) { current_user.recent_cables }

  expose(:events) do
    scope = Grid::View.where rentable: [villas.reorder(nil), boats.reorder(nil)]

    # Hash<year, Hash<rentable_type, Hash<rentable_id, Array<Grid::View>>>
    [current_year, current_year + 1].to_h do |year|
      start_date = Date.new(year, 1, 1)
      end_date   = Date.new(year, 12, 31)

      items = Hash.new { |types, type|
        types[type] = Hash.new { |ids, id| ids[id] = [] }
      }
      scope.capped_between(start_date, end_date).each do |gv|
        items[gv.rentable_type][gv.rentable_id] << gv
      end

      [year, items]
    end
  end

  def index
    # `super` greift auf InheritedResources/CanCan zurück
    # (nutzen wir hier beides nicht)
  end

  private

  def item_utilization(year, item)
    u = item.utilization_in_year year, events[year][item.model_name.to_s][item.id]
    format "%d %%", u
  end
end
