import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { format: { type: String, default: "short" } }

  connect() {
    const dt = this.element.getAttribute("datetime")
    if (!dt) return
    const date = new Date(dt)
    if (isNaN(date.getTime())) return
    this.element.textContent = this.formatDate(date)
    if (this.formatValue === "relative") {
      this.element.title = this.fullFormat(date)
    }
  }

  formatDate(date) {
    switch (this.formatValue) {
      case "long":
        return new Intl.DateTimeFormat(undefined, {
          year: "numeric", month: "2-digit", day: "2-digit",
          hour: "2-digit", minute: "2-digit", second: "2-digit"
        }).format(date)
      case "relative":
        return this.relativeFormat(date)
      default:
        return new Intl.DateTimeFormat(undefined, {
          month: "short", day: "numeric",
          hour: "2-digit", minute: "2-digit"
        }).format(date)
    }
  }

  fullFormat(date) {
    return new Intl.DateTimeFormat(undefined, {
      year: "numeric", month: "short", day: "numeric",
      hour: "2-digit", minute: "2-digit", second: "2-digit",
      timeZoneName: "short"
    }).format(date)
  }

  relativeFormat(date) {
    const diff = date.getTime() - Date.now()
    const absDiff = Math.abs(diff)
    const rtf = new Intl.RelativeTimeFormat(undefined, { numeric: "auto" })

    const seconds = Math.floor(absDiff / 1000)
    if (seconds < 60) return rtf.format(diff < 0 ? -seconds : seconds, "second")

    const minutes = Math.floor(absDiff / 60000)
    if (minutes < 60) return rtf.format(diff < 0 ? -minutes : minutes, "minute")

    const hours = Math.floor(absDiff / 3600000)
    if (hours < 24) return rtf.format(diff < 0 ? -hours : hours, "hour")

    const days = Math.floor(absDiff / 86400000)
    return rtf.format(diff < 0 ? -days : days, "day")
  }
}