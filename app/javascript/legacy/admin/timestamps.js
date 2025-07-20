import { format, parseISO } from "date-fns"

$.fn.moment = function() {
  $(this).find(".timestamp").each(function() {
    const $this = $(this),
          time = parseISO($this.text().trim()),
          fmt = $this.data("format") || "PPPPp"

    return $this.text(format(time, fmt))
  }).end()
}

$(function() {
  $("body").moment()
})
