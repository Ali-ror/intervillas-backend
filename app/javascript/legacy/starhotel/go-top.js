import { debounce } from "lodash"

document.addEventListener("DOMContentLoaded", () => {
  const handle = document.getElementById("go-top")
  if (!handle) {
    return
  }

  const onScroll = debounce(function() {
    handle.classList.toggle("show", window.scrollY > 500)
  }, 200)

  window.addEventListener("scroll", onScroll)
})
