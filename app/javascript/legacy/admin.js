import "./intervillas/review"

import "./lib/fullcalendar"

import "./admin/bookings/dateapplier"
import "./admin/bookings/messages"
import "./admin/bookings/payments"

import "./starhotel/digineo.core"
import "./admin/digineo.formtastic"
import "./admin/dynamic_add_fields"
import "./admin/form-remote-message"
import "./admin/high_seasons"
import "./admin/intervillas.billings"
import "./admin/intervillas.calendar"
import "./admin/location_hash_tabs"
import "./admin/overview"
import "./admin/tags"
import "./admin/timestamps"

import "./plugins/actionrows"
import "./plugins/jquery.stickytableheaders"

$(function() {
  $("table.js-sticky-header, .not-a-table.js-sticky-header").stickyTableHeaders({ fixedOffset: 0 })

  const envBanner = document.querySelector(".environment-banner")
  if (envBanner) {
    envBanner.addEventListener("mouseenter", () => {
      envBanner.classList.toggle("environment-banner-left")
      envBanner.classList.toggle("environment-banner-right")
    })
  }
})
