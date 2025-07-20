import { throttle } from "lodash"

document.addEventListener("DOMContentLoaded", () => {
  const header = document.querySelector("body > header")
  if (!header || !header.classList.contains("navbar-transparent")) {
    // <header/> not found, or header is not transparent
    return
  }

  let menuOpen = false, // main menu (Boostrap collapse)
      offsetReached = false // scroll pos > offset
  const toggleTransparency = () => header.classList.toggle("navbar-transparent", !offsetReached && !menuOpen)

  const toggle = throttle(() => {
    offsetReached = (window.pageYOffset || document.documentElement.scrollTop) >= (0.33 * window.innerHeight)
    toggleTransparency()
  }, 100, {
    leading:  false,
    trailing: true,
  })

  window.addEventListener("scroll", toggle, { passive: true })
  setTimeout(toggle, 100)

  // interaction with collapsable main menu (Boostrap)
  $("#main-menu").on("show.bs.collapse", () => {
    menuOpen = true
    toggleTransparency()
  }).on("hide.bs.collapse", () => {
    menuOpen = false
    toggleTransparency()
  })
})
