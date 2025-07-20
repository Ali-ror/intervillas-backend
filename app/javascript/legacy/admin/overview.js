$(document).on("click", ".js-toggle-hidden [data-toggle='hidden']", e => {
  e.preventDefault()
  $(this).closest(".js-toggle-hidden").find("[data-hidden]").toggleClass("hidden")
})
