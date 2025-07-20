import { railsClient as axios } from "../../intervillas-drp/utils"

export function createCallback(handler) {
  const name = `_initMaps_${new Date().valueOf()}`
  window[name] = handler
  return name
}

export async function fetchMapData(url, initMaps) {
  const { data } = await axios.post(url)
  const callback = createCallback(() => initMaps(window["google"].maps))

  const api = document.createElement("script")
  api.async = true
  api.src = `https://maps.google.com/maps/api/js?key=${data.api_key}&callback=${callback}`
  document.head.appendChild(api)

  return data.payload
}

const clusterMarkerSvg = color => `<svg fill="${color}" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240">
  <circle cx="120" cy="120" opacity=".9" r="70" />
  <circle cx="120" cy="120" opacity=".5" r="110" />
</svg>`

export class ClusterRenderer {
  constructor(maps, textColor, bgColor) {
    this.maps = maps

    this.setColors(textColor, bgColor)
  }

  setColors(text, bg) {
    this.bgColor = bg
    this.textColor = text
  }

  render({ count, position }, _stats) {
    const svg = window.btoa(clusterMarkerSvg(this.bgColor))

    return new this.maps.Marker({
      position,
      icon: {
        url:        `data:image/svg+xml;base64,${svg}`,
        scaledSize: new this.maps.Size(45, 45),
      },
      label: {
        text:     String(count),
        color:    this.textColor,
        fontSize: "12px",
      },
      zIndex: Number(this.maps.Marker.MAX_ZINDEX) + count,
    })
  }
}
