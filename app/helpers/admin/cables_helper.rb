module Admin::CablesHelper

  def cable_recipient_list(booking)
    contacts = []

    if r = booking.villa
      contacts.push r.owner.presence
      contacts.push r.manager.presence
    end

    if r = booking.boat
      contacts.push r.owner.presence
      contacts.push r.manager.presence
    end

    contacts.compact.uniq.map {|c| [c.name, c.id] }
  end

end
