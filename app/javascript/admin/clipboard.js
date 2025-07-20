import ClipboardJS from "clipboard"

const clipboard = new ClipboardJS(".fa-files-o")

clipboard.on("success", e => {
  const tooltip = $(e.trigger).tooltip({ title: "kopiert", placement: "top" })
  tooltip.tooltip("show")
  setTimeout(() => tooltip.tooltip("destroy"), 2000)
})
