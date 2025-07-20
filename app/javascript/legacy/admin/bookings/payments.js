$(document).on("click", ".js-apply-payment", function(e) {
  e.preventDefault()

  const data = $(this).data(),
        form = $(data.target)
  if (!form.length) {
    return
  }

  const scope = form.find('[name="payment[scope]"]'),
        sum = form.find('[name="payment[sum]"]'),
        paidOn = form.find('[name="payment[paid_on]"]')
  if (scope.length) {
    scope.val(data.scope)
  }
  if (sum.length) {
    sum.val(data.sum)
  }
  if (paidOn.length) {
    paidOn.trigger("focus")
  }
}).on("ajax:success", ".js-acknowledge-downpayment", e => {
  const tr = $(e.target).closest("tr")

  if (tr.data("on-ack") === "reload") {
    window.location.reload(true)
  } else {
    tr.hide(500, () => tr.remove())
  }
}).on("ajax:error", ".js-acknowledge-downpayment", e => {
  const xhr = e.detail[2],
        msg = ["Konnte unvollständige Anzahlung nicht akzeptieren."]

  if (xhr.responseJSON?.error) {
    msg.push("", xhr.responseJSON.error)
  }

  alert(msg.join("\n"))
})
