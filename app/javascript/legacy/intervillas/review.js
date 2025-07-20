import { debounce } from "lodash"
import "./init-split-text"

function buildPreviewFun(form, target) {
  // zweimal dieselbe Vorschau brauchen wir nicht abholen
  let lastUpdate = null

  return () => {
    const currentUpdate = form.serialize()
    if (currentUpdate === lastUpdate) {
      return
    }

    const data = form.serializeArray().reduce((memo, item) => {
      if (item.name !== "_method") {
        memo[item.name] = item.value
      }
      return memo
    }, {})

    $.post(form.data("preview-url"), data, preview => {
      lastUpdate = currentUpdate // jetzt hat sich erst was geändert
      target.find(".item").empty().append(preview)
      $("#preview-bar").removeClass("hidden")
    }, "html")
  }
}

$(function() {
  const form = $("form.edit-review[data-preview-url]"),
        preview = $("#preview-box")
  if (!form.length || !preview.length) {
    return
  }

  const onChange = debounce(buildPreviewFun(form, preview), 500)
  form.on("change keyup", onChange)
  onChange()
})
