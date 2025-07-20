document.addEventListener("DOMContentLoaded", () => {
  const rc = document.getElementById("rental-cars")
  if (!rc) {
    return
  }

  const origin = "https://www.rentalcars.com"
  const params = [
    `affiliateCode=${rc.dataset.code || "intervilla"}`,
    `preflang=${rc.dataset.lang || "de"}`,
    "fts=true",
  ].join("&")
  const url = `${origin}/partners/integrations/stand-alone-app/?${params}`

  const iframe = document.createElement("iframe")
  iframe.classList.add("mt-5")
  ;[
    ["src",               url],
    ["width",             "100%"],
    ["height",            700],
    ["scrolling",         "no"],
    ["frameborder",       0],
    ["allowTransparency", "true"],
  ].forEach(([attr, val]) => {
    iframe.setAttribute(attr, val)
  });

  window.addEventListener("message", (ev) => {
    if (ev.origin === origin) {
      iframe.setAttribute("height", ev.data)
    }
  }, false)

  rc.replaceWith(iframe)
  iframe.dispatchEvent(new CustomEvent("resize"))
})
