$(document).on("click", "form [data-toggle='add-association']", function(e) {
  e.preventDefault()
  const data = $(this).data()
  const template = $(`#${data.template}`)

  // Zeitstempel-ID setzen
  const newId = new Date().getTime(),
        content = template.text().replace(/__new_id__/g, newId)

  // Template einfügen
  $(".js-add-association").append(content)
}).on("click", "form [data-toggle='remove-association']", function(e) {
  e.preventDefault()
  $(this).closest(".nested-fields")
    .find("input[name$='[_destroy]']").val("1").end()
    .hide()
})
