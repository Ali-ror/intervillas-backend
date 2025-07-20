$(document).on("click", "[data-toggle='paypal_how_it_works']", function(e) {
  e.preventDefault()
  const opts = [
    "toolbar=no",
    "location=no",
    "directories=no",
    "status=no",
    "menubar=no",
    "scrollbars=yes",
    "resizable=yes",
    `width=${Math.min(1060, $(window).outerWidth())}`,
    `height=${Math.min(700, $(window).outerHeight())}`,
  ].join(", ")

  window.open($(this).attr("href"), "WIPaypal", opts)
  return false
})
