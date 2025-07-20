module Api::Admin::Common
  def blockings
    select(Blocking.not_ignored)
  end

  def select(scope)
    scope
      .for_rentable(rentable_type, rentable_id)
      .between(start_time, end_time)
      .map { |e| e.to_event_hash(rentable_type) }
  end

  def rentable_id
    params.require(rentable_type)
  end

  def rentable_type
    @rentable_type ||= params.keys.find do |key|
      %w[ boat villa ].include? key
    end
  end

  def start_time
    params.require(:between).require(:start)
  end

  def end_time
    params.require(:between).require(:end)
  end
end
