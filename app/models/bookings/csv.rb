module Bookings::Csv
  extend ActiveSupport::Concern

  included do
    comma do
      number
      start_date
      end_date
      villa
      name
      csv_state @instance.class.human_attribute_name(:state)
      adults
      csv_children_under_12 @instance.class.human_attribute_name(:children_under_12)
      csv_children_under_6  @instance.class.human_attribute_name(:children_under_6)
      csv_boat_state        @instance.class.human_attribute_name(:boat_state)
    end

    comma :manager_owner do
      number
      start_date
      end_date
      villa
      csv_boat_state @instance.class.human_attribute_name(:boat_state)
    end
  end

  def csv_children_under_6
    children_under_6.to_s
  end

  def csv_children_under_12
    children_under_12.to_s
  end

  def csv_state
    I18n.t(state, scope: :states)
  end

  def csv_boat_state
    I18n.t(boat_state == "" ? "unknown" : boat_state, scope: :boat_states)
  end
end
