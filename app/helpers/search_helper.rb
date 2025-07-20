module SearchHelper
  def search_scope(field, default = nil)
    params.fetch(field, default) || default
  end

  def search_scope_date(field, default)
    l search_scope(field, default).to_date
  rescue StandardError
    l default.to_date
  end

  def search_criteria_args
    @search_criteria_args ||= {
      people:     search_scope(:people, 2).to_i,
      rooms:      search_scope(:rooms, 1).to_i,
      start_date: search_scope_date(:start_date, Date.current),
      end_date:   search_scope_date(:end_date, Date.current + VillaInquiry.minimum_booking_nights(Date.current) + 1),
    }
  end

  def facet_search_configuration(facets: true)
    rooms, beds = Villa.minmax_beds_and_rooms_count.values_at(:rooms, :beds)

    {
      facets:      facets, # true = offer "more filter" buttons
      query:       {
        people:     search_scope(:people, 2).to_i,
        rooms:      search_scope(:rooms, rooms[0]).to_i,
        start_date: search_scope(:start_date, nil),
        end_date:   search_scope(:end_date, nil),
        tags:       search_scope(:tags, "").split(",").map(&:to_i),
        locations:  search_scope(:locations, "").split(","),
      },
      constraints: {
        rooms:  rooms,
        people: beds,
      },
      urls:        {
        facets: facets_api_villas_path(locale: I18n.locale),
      },
    }
  end

  def search_criteria_period
    {
      start_date: search_scope(:start_date),
      end_date:   search_scope(:end_date),
    }
  end

  def link_to_villa_with_search(villa, *args, &block)
    link_to villa_path(villa, **search_criteria_period), *args, &block
  end
end
