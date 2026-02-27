import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "placeholder", "wrapper", "image"]
  static values  = { existingUrl: String }

  // edit で既存画像 URL が渡されていれば即時プレビュー表示
  connect() {
    if (this.existingUrlValue) {
      this.imageTarget.src = this.existingUrlValue
      this.#show()
    }
  }

  // 「写真を登録する」「変更」ボタンから file input を開く
  openPicker() {
    this.inputTarget.click()
  }

  // file input change → FileReader でプレビュー更新
  show() {
    const file = this.inputTarget.files[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (e) => {
      this.imageTarget.src = e.target.result
      this.#show()
    }
    reader.readAsDataURL(file)
  }

  // 「削除」ボタン → 選択をクリアして初期状態に戻す
  reset() {
    this.inputTarget.value = ""
    this.imageTarget.src   = ""
    this.#hide()
  }

  // ─── private ─────────────────────────────────────────────

  #show() {
    this.wrapperTarget.classList.remove("hidden")
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add("hidden")
    }
  }

  #hide() {
    this.wrapperTarget.classList.add("hidden")
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.remove("hidden")
    }
  }
}
