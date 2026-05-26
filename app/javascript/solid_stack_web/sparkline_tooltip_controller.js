import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "tip"]

  connect() {
    this._tip = this.tipTarget
  }

  show({ currentTarget }) {
    const label = currentTarget.dataset.tip
    if (!label) return
    const rect = currentTarget.getBoundingClientRect()
    this._tip.textContent = label
    this._tip.style.left = `${rect.left + rect.width / 2}px`
    this._tip.style.top = `${rect.top - 6}px`
    this._tip.hidden = false
  }

  hide() {
    this._tip.hidden = true
  }
}