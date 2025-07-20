const GENERIC_SUCCESS_MESSAGE = "Daten erfolgreich gespeichert"
const GENERIC_ERROR_MESSAGE = "es ist ein Fehler aufgetreten"

class FormRemoteMessage {
  constructor(form) {
    this.form = form
    this.target = this.form.find(".js-form-remote-message")
  }

  clear() {
    this.target.empty()
  }

  success(xhr) {
    this.target
      .text(this.messageFromXHR(xhr, GENERIC_SUCCESS_MESSAGE))
      .append('<i class="fa fa-fw fa-check"></i>')
      .removeClass("text-danger")
      .addClass("text-success")
  }

  error(xhr) {
    this.target
      .text(this.messageFromXHR(xhr, GENERIC_ERROR_MESSAGE))
      .append('<i class="fa fa-fw fa-exclamation-triangle"></i>')
      .removeClass("text-success")
      .addClass("text-danger")
  }

  messageFromXHR(xhr, fallback) {
    if (!xhr) {
      return fallback
    }

    const msg = xhr.responseJSON
      ? xhr.responseJSON
      : xhr.responseText
        ? xhr.responseText
        : null

    return msg?.message || fallback
  }
}

function injectFormRemoteMessage(form) {
  let fmr = form.data("FormRemoteMessage")
  if (!fmr) {
    fmr = new FormRemoteMessage(form)
    form.data("FormRemoteMessage", fmr)
  }
  return fmr
}

$(document).on("ajax:beforeSend change", "form[data-remote]", function() {
  injectFormRemoteMessage($(this)).clear()
}).on("ajax:success", "form[data-remote]", function(e) {
  const xhr = e.detail[2]
  injectFormRemoteMessage($(this)).success(xhr)
}).on("ajax:error", "form[data-remote]", function(e) {
  const xhr = e.detail[2]
  injectFormRemoteMessage($(this)).error(xhr)
})
