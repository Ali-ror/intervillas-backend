/* global process */

// Skripte für verschiedene Mail-Vorschau-Buttons:
//
// .js-message-preview
//   - holt ein Vorschau-Modal per AJAX ab
//   - Message existiert schon, Button hat `remote: true` gesetzt
//
// .js-message-live-preview
//   - holt ein Vorschau-Modal per AJAX ab
//   - Message existiert noch nicht
//   - sendet zuerset Form-Daten per POST an den Server

function showMessagePreview(content) {
  const modal = $(content),
        iframe = modal.find("iframe")

  modal.on("shown.bs.modal", () => {
    // iframe.contents() ist erst verfügbar, wenn der iframe im DOM hängt
    // (FF: und dort auch angezeigt wird)
    const ctx = iframe.contents()

    // in Chrome ist ctx.innerHeight() == 600 (kommt aus dem height-Attribut),
    // und in FF ist ctx.find("html").innerHeight() == 0. Beides ist nicht
    // richtig...
    const h = ctx.find("html").innerHeight()
    iframe.height(h === 0 ? ctx.innerHeight() : h)
  })
    .on("hidden.bs.modal", () => {
      modal.remove()
    })
    .appendTo("body")
    .modal()
}

function showErrorModal(error, text) {
  const modal = $(`
    <div class="modal">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header alert-danger">
            <button type="button" class="close" data-dismiss="modal"><i class="fa fa-times"></i></button>
            <h4 class="modal-title">${error}</h4>
          </div>
          <div class="modal-body"><pre class="small">/pre></div>
        </div>
      </div>
    </div>
  `)

  modal.on("hidden.bs.modal", () => {
    modal.remove()
  }).find(".modal-body pre").text(text).end()
    .appendTo("body")
    .modal()
}

$(document)
  .on("ajax:success", ".js-update-message-status, .js-resend-message", function(e) {
    const xhr = e.detail[2]
    $(this).closest(".panel").replaceWith($(xhr.responseText).moment())
  })
  .on("ajax:success", ".js-message-preview", function(e) {
    const xhr = e.detail[2]
    showMessagePreview(xhr.responseText)
  })
  .on("ajax:error", ".js-message-preview", function(e) {
    const [error, status, xhr] = e.detail
    switch (process.env.NODE_ENV) {
    case "development":
      showErrorModal(status, xhr.responseText)
      break
    case "test":
      console.error("Message Preview", error)
      break
    case "production":
    case "staging":
      alert("Konnte Vorschau nicht genrieren.")
      break
    }
  })
  .on("click", ".js-message-live-preview", function(e) {
    e.preventDefault()
    const btn = $(this),
          url = btn.data("preview-url")
    const data = btn.closest("form").serializeArray().reduce((memo, curr) => {
      memo[curr.name] = curr.value
      return memo
    }, {})

    $.post(url, data)
      .done((data, status, xhr) => {
        showMessagePreview(data)
      })
      .fail(() => {
        alert("Konnte Vorschau nicht generieren.")
      })
  })
