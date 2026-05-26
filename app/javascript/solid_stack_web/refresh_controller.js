import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 5000 } }

  initialize() {
    this._onVisibilityChange = this._onVisibilityChange.bind(this)
  }

  connect() {
    document.addEventListener("visibilitychange", this._onVisibilityChange)
    this._schedule()
  }

  disconnect() {
    clearTimeout(this._timer)
    document.removeEventListener("visibilitychange", this._onVisibilityChange)
  }

  _schedule() {
    this._timer = setTimeout(() => this._reload(), this.intervalValue)
  }

  async _reload() {
    clearTimeout(this._timer)
    const hasSelection = this.element.querySelector("input[type='checkbox']:checked")
    if (!document.hidden && !hasSelection) {
      try {
        const response = await fetch(window.location.href, {
          headers: { "Turbo-Frame": this.element.id, Accept: "text/html" }
        })
        if (response.ok) {
          const html = await response.text()
          const doc = new DOMParser().parseFromString(html, "text/html")
          const frame = doc.querySelector(`turbo-frame#${this.element.id}`)
          if (frame && this.element.isConnected) this.element.innerHTML = frame.innerHTML
        }
      } catch {
        // network error — skip this tick
      }
    }
    if (this.element.isConnected) this._schedule()
  }

  _onVisibilityChange() {
    if (document.hidden) {
      clearTimeout(this._timer)
    } else if (!this.element.querySelector("input[type='checkbox']:checked")) {
      this._reload()
    }
  }
}