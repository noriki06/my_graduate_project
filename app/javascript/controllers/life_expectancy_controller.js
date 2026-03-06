import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    console.log("life-expectancy controller connected")
  }

  setValue(event) {
    const value = event.currentTarget.dataset.value
    console.log("clicked", value)
    this.inputTarget.value = value
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
