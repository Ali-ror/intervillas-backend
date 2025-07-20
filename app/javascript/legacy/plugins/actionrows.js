const actionRow = "table.js-action-row td"

$(document).on("click", `${actionRow} a, ${actionRow} button`, (e) => {
  e.stopPropagation()
}).on("click", actionRow, (e) => {
  const elem = $(e.target),
        id = elem.closest("tr[data-action-row-id]").data("action-row-id"),
        url = elem.closest("table[data-action-row-url]").data("action-row-url")

  window.location.href = url.replace(/:id\b/, id)
})
