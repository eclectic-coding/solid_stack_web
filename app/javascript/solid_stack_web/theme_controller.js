import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    const saved = localStorage.getItem("sqw-theme")
    const preferred = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
    this.apply(saved || preferred)
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme") || "light"
    const next = current === "dark" ? "light" : "dark"
    localStorage.setItem("sqw-theme", next)
    this.apply(next)
  }

  apply(theme) {
    document.documentElement.setAttribute("data-theme", theme)
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = theme === "dark" ? "☀" : "☽"
      this.toggleTarget.setAttribute("aria-label", theme === "dark" ? "Switch to light mode" : "Switch to dark mode")
    }
  }
}