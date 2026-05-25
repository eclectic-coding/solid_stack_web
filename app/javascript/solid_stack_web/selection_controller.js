import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "bar", "count"]

  toggle() {
    this._update()
  }

  selectAll({ target }) {
    this.checkboxTargets.forEach(cb => cb.checked = target.checked)
    this._update()
  }

  submit({ params: { formId } }) {
    const form = document.getElementById(formId)
    if (!form) return
    form.querySelectorAll("[data-injected-id]").forEach(el => el.remove())
    this.checkboxTargets
      .filter(cb => cb.checked)
      .forEach(cb => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = "job_ids[]"
        input.value = cb.value
        input.dataset.injectedId = true
        form.appendChild(input)
      })
    form.requestSubmit()
  }

  _update() {
    const checked = this.checkboxTargets.filter(cb => cb.checked).length
    const total = this.checkboxTargets.length
    if (this.hasBarTarget) this.barTarget.style.display = checked > 0 ? "" : "none"
    if (this.hasCountTarget) this.countTarget.textContent = checked
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.indeterminate = checked > 0 && checked < total
      this.selectAllTarget.checked = total > 0 && checked === total
    }
  }
}