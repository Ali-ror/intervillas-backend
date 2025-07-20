const delay = (() => {
  let timer = 0
  return (callback, ms) => {
    clearTimeout(timer)
    timer = setTimeout(callback, ms)
  }
})()

const int = val => parseInt(val, 10)

$(function() {
  const nav = $("#confirmation-nav")
  if (!nav.length) {
    return
  }

  // wait for browser to jump to location
  keepConsistentWidth(nav)
  setTimeout(() => traceNavigation(nav)), 100
})

function traceNavigation(nav) {
  nav.affix({
    offset: {
      top() {
        this.top = nav.offset().top - $("header").outerHeight(true) - int(nav.children(0).css("margin-top"))
      },
      bottom() {
        this.bottom = $("footer").outerHeight(true)
      },
    },
  }).on("affix.bs.affix", () => {
    const parent = nav.parent()
    nav.css({
      width:    parent.innerWidth() - int(parent.css("padding-left")) - int(parent.css("padding-right")),
      top:      $("header").outerHeight(true),
      position: "fixed",
    })
  }).on("affixed-top.bs.affix", () => {
    nav.css({
      top:      "",
      position: "",
    })
  }).on("affixed-bottom.bs.affix", () => {
    nav.css({
      position: "absolute",
      top:      $("header").outerHeight(true),
    })
  })

  $("body").scrollspy({
    target: "#" + nav.attr("id"),
    offset: $("header").outerHeight(true),
  })
}

function keepConsistentWidth(nav) {
  const parent = nav.parent()

  const resizeNav = () => {
    const w = nav.is(".affix")
      ? parent.innerWidth() - int(parent.css("padding-left")) - int(parent.css("padding-right"))
      : ""
    nav.css("width", w)
  }

  $(window).on("resize", () => {
    delay(resizeNav, 100)
  })

  // on page reload, the browser scrolls to the previous position without
  // triggering scroll events. BS-Affix also does not trigger its *.bs.affix
  // (but sets the "affix" class nonetheless...)
  setTimeout(resizeNav, 150)
}
