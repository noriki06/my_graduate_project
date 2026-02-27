import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["daySection", "daySelect"]

  connect() {
    this.#update()
  }

  // フォーム内の change イベントをまとめて受け取る
  change() {
    this.#update()
  }

  #update() {
    const weekly = this.element.querySelector('input[type="radio"][value="weekly"]')
    const isWeekly = weekly?.checked === true

    this.daySectionTarget.classList.toggle("hidden", !isWeekly)
    this.daySelectTarget.disabled = !isWeekly
  }
}
