const toggleFormChilren = event => {
  event.preventDefault()

  const btn = $(event.target)
  btn.parents("legend").siblings().toggle()
  btn.toggleClass("hide-children show-children")
}

// Formular-Felder ein-/ausklappen
function setupFormToggler($root) {
  $root.find("form fieldset.collapsable legend").each(function() {
    const btn = $(`
      <a href='#' class='form-chilren-toggle hide-children'>
        ${$(this).text()} <span>[&pm;]</span>
      </a>
    `).on("click", toggleFormChilren)

    $(this).empty().append(btn)
    if ($(this).parent().is(".collapsed")) {
      btn.trigger("click")
    }
  })
}

$(function() {
  setupFormToggler($("body"))
})
