$(document).on("click", ".js-apply-date .js-btn", function(e) {
  const button = $(this),
        container = button.closest(".js-apply-date")

  ;["month", "year"].forEach(f => () => {
    const field = `${container.data(`${f}-field`)}`.trim()
    if (field) {
      const input = $(`#${field}`)
      if (input.length) {
        input.val(button.data(f))
      }
    }
  })
})
