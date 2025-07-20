$(function() {
  let $billingHasChanged = false
  $("#charges-form").on("change keyup", function(e) {
    if ($billingHasChanged) {
      return
    }

    $(this).addClass("changed")
    $billingHasChanged = true
  })
})
