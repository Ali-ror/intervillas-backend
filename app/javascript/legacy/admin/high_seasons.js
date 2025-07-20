$(function() {
  var setCheckedWithoutTriggeringEvent = function(el, isChecked) {
    el.prop("checked", isChecked)
  }

  $("[data-select-all]").each(function() {
    var input = $(this),
        collection = $(input.data("select-all")),
        allSelected = true

    var update = function() {
      collection.each(function() {
        allSelected = allSelected && this.checked
      })
      setCheckedWithoutTriggeringEvent(input, allSelected)
    }

    collection.on("change", function() {
      allSelected = true
      update()
    })
    input.on("change", function() {
      setCheckedWithoutTriggeringEvent(collection, input.is(":checked"))
    })
    update()
  })
})
