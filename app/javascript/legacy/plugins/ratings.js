$.fn.rating = function() {
  return $(this).each(function() {
    const group = $(this),
          input = group.find("input:hidden")
    let active = group.find(".star.active")

    group.find(".star").on("mouseover", () => {
      active.removeClass("active")
    }).on("mouseleave", () => {
      active.addClass("active")
    }).on("click", function() {
      active = $(this)
      if (active.data("value") !== input.val()) {
        input.val(active.data("value"))
        group.trigger("change")
      }
    })
  })
}

$(function() {
  $("form .rating").rating()
})
