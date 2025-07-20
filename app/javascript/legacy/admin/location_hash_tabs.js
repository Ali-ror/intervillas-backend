// activate tab based on location hash
function activateTab() {
  const currentHash = window.location.hash.replace("/", "")
  if (!currentHash.length) {
    return
  }

  const activeTab = $(`[href='${currentHash}']`)
  if (activeTab && !activeTab.closest("li").hasClass("active")) {
    activeTab.tab("show")
  }
}

$(function() {
  // don't do anything if there's no tab which could trigger the location to change
  const navs = $(".js-main-nav [data-toggle='tab'], .js-main-nav [data-toggle='pill']")
  if (!navs.length) {
    return
  }

  // trigger when the page loads
  activateTab()

  // trigger when the hash changes (forward / back)
  $(window).on("hashchange", () => {
    activateTab()
  })

  // sync location.hash on tab navigation. if the browser scroll to an
  // element with id === location.hash, correct for the navbar blocking
  // parts of the element.
  //
  // for anchors with href === "#id" set the location.hash to "/id", to
  // prevent the browser from jumping wildly between the target element
  // and (0,0).
  navs.on("shown.bs.tab", function() {
    window.location.hash = $(this).attr("href").replace("#", "/")
    window.scrollTo(0, 0)
  })
})
