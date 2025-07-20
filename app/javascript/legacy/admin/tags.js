const RTF_SELECTOR = "form.js-remote-tag-form"
const RTF_DATA_ID = "RemoteTagForm"

class RemoteTagForm {
  constructor(container) {
    this.container = container
    this.container.data(RTF_DATA_ID, this)
    this.groups = this.container.find(".form-group")
  }

  beforeSend() {
    this.enableForm(false)
    this.groups.removeClass("has-error").find(".help-block").remove()
    this.container.removeClass("has-error has-success")
  }

  onSuccess() {
    this.container.addClass("has-success")
  }

  onError(data) {
    this.container.addClass("has-error")

    for (const [k, errs] of Object.entries(data)) {
      const group = this.groups.find(`[name='tag[${k}]']`).parent()
      errs.forEach(err => {
        group.append`<span class="help-block small">${err}</span>`
      })
    }
  }

  onComplete() {
    this.enableForm(true)
  }

  enableForm(on_off) {
    this.container.find(":input, select").prop("disabled", !on_off)
  }
}

$(document).on("ajax:beforeSend", RTF_SELECTOR, ev => {
  const row = $(ev.target),
        rtf = row.data(RTF_DATA_ID) || new RemoteTagForm(row)
  rtf.beforeSend()
}).on("ajax:success", RTF_SELECTOR, ev => {
  $(ev.target).data(RTF_DATA_ID).onSuccess()
}).on("ajax:error", RTF_SELECTOR, ev => {
  const xhr = ev.detail[2]
  $(ev.target).data(RTF_DATA_ID).onError(xhr.responseJSON?.errors || {})
}).on("ajax:complete", RTF_SELECTOR, ev => {
  $(ev.target).data(RTF_DATA_ID).onComplete()
})
