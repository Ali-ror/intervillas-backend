class InquiryConsistencyChecker < SimpleDelegator # wrappt Inquiry
  # Prüft Inkonsistenzen und gibt eine Liste von I18n-Keys unterhalb des
  # Scopes "inquiries.inconsistencies" zurück.
  def inconsistencies
    return [] unless with_boat?

    [
      ("boat.not_possible"  unless boat_possible?),
      ("boat.date_mismatch" unless boat_date_matches?),
      ("boat.pool_mismatch" unless boat_pool_matches?),
    ].compact
  end

  # Liegt der Boot-Zeitraum ausserhalb der Villa-Zeitraums?
  def boat_date_matches?
    boat_inquiry.start_date > villa_inquiry.start_date &&
      boat_inquiry.end_date < villa_inquiry.end_date
  end

  # Gehört das Boot zu den mietbaren Booten der Villa?
  def boat_pool_matches?
    villa.boats.map(&:id).include? boat_inquiry.boat_id
  end
end
