import { format } from "date-fns"

$(function() {
  const dates = {
    start_date: null,
    end_date:   null,
  }

  $(".js-calendar").each(function(index, calendar_elem) {
    const $calendar = $(calendar_elem),
          calendarViewMode = $calendar.data("view-mode") !== 0,
          toHighlight = Number($calendar.data("to-highlight"))

    const newBlockingPath = dates => {
      const data = $calendar.data(),
            path = data.newBlockingPath
      dates.villa_id = data.villaId
      dates.boat_id = data.boatId
      return [path, $.param(dates)].join("?")
    }

    const events = $calendar.data("event-url")
    // events = [] if events? && events.indexOf('for_villa') == -1

    const options = {
      events:     events,
      startParam: "between[start]",
      endParam:   "between[end]",

      dayClick(date, allDay, jsEvent, view) {
        if (calendarViewMode) {
          return
        }

        const d = format(date, "yyyy-MM-dd")
        if (dates.start_date) {
          dates.end_date = d
        } else {
          dates.start_date = d
        }
        if (dates.start_date && dates.end_date && dates.end_date < dates.start_date) {
          const { start_date, end_date } = dates
          dates.start_date = end_date
          dates.end_date = start_date
        }

        $(this).css({ "background-color": "yellow" })
        if (dates.end_date) {
          location.assign("" + location.origin + newBlockingPath(dates))
        }
      },

      eventClick(event, jsEvent, view) {
        window.location.assign("" + location.origin + event.path)
      },

      loading(isLoading, view) {
        if (!isLoading || !toHighlight) {
          return
        }

        setTimeout(() => {
          const events = $calendar.fullCalendar("clientEvents")
          for (let i = 0, len = events.length; i < len; ++i) {
            const event = events[i]
            if (events.id === toHighlight) {
              event.editable = true
            } else {
              event.className.push("fc-state-disabled")
            }

            $calendar.fullCalendar("updateEvent", event)
          }
        }, 100)
      },
    }

    const date = $calendar.data("goto-date")
    if (date) {
      const [y, m] = date.split("-").map(e => parseInt(e, 10))
      options.year = y
      options.month = m - 1
    }

    $calendar.fullCalendar(options)
  })

  $('a[data-toggle=pill][href="#villa"], a[data-toggle=pill][href="#boat"]').on("shown.bs.tab", e => {
    $(".js-calendar").fullCalendar("render")
  })

  document.addEventListener("change.start-date", e => {
    const start_date = e.detail.start_date

    if (start_date) {
      $(".js-calendar").fullCalendar("gotoDate", start_date)
    }

    $(".js-calendar").fullCalendar("render")
  })
})
