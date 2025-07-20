function initSplitTextExpand($base) {
  $base.find(".split-text a.split-text-expand").on("click", function(e) {
    e.preventDefault()
    $(this).closest(".split-text").addClass("split-text-more").end().remove()
  })
}

$(function() {
  initSplitTextExpand($("body"))
})
