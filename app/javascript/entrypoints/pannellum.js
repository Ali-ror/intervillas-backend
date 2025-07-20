import "pannellum/src/js/libpannellum"
import "pannellum/src/js/pannellum"
import "pannellum/src/css/pannellum.css"
import "../stylesheets/vendor/pannellum.sass"

function configWithDefaults(config) {
  const update = (key, value) => {
    if (!config.hasOwnProperty(key)) {
      config[key] = value
    }
  }

  update("type", "equirectangular")
  update("hfov", 120) // max zoom out
  update("autoLoad", true)
  update("autoRotate", -0.5)
  update("autoRotateInactivityDelay", 3000)
  update("showControls", true)
  return config
}

function loadConfig() {
  const container = document.getElementById("container")
  if (!container) {
    console.error("no config found: missing container")
    return
  }

  const data = container.dataset.tour
  if (!data) {
    console.error("no config found: missing dataset")
    return
  }

  try {
    const json = JSON.parse(data)
    if (json) {
      return configWithDefaults(json)
    }
  } catch (err) {
    console.error(`no config found: ${err}`)
  }
}

window.addEventListener("load", () => {
  /* global pannellum */
  pannellum.viewer("container", loadConfig())
})
