import { Controller } from "@hotwired/stimulus"

const PERSIST_KEYS = ["status", "period", "queue"]

export default class extends Controller {
  static values = { key: String }

  connect() {
    const params = new URLSearchParams(window.location.search)

    if (params.toString()) {
      const toSave = new URLSearchParams()
      PERSIST_KEYS.forEach(k => { if (params.get(k)) toSave.set(k, params.get(k)) })
      if (toSave.toString()) this.write(toSave.toString())
    } else {
      const stored = this.read()
      if (stored) window.location.replace(`${window.location.pathname}?${stored}`)
    }
  }

  read() {
    try { return localStorage.getItem(this.keyValue) } catch (e) { return null }
  }

  write(value) {
    try { localStorage.setItem(this.keyValue, value) } catch (e) { /* ignore */ }
  }
}