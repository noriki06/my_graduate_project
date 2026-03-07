import { Controller } from "@hotwired/stimulus"

const MAX_PX  = 1200  // 長辺の最大ピクセル数
const QUALITY = 0.82  // JPEG 品質

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

  // file input change → 圧縮してからプレビュー更新
  async show() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const compressed = await this.#compress(file)

    // input の files を圧縮済みファイルに差し替え（アップロード対象も圧縮版になる）
    const dt = new DataTransfer()
    dt.items.add(compressed)
    this.inputTarget.files = dt.files

    this.imageTarget.src = URL.createObjectURL(compressed)
    this.#show()
  }

  // 「削除」ボタン → 選択をクリアして初期状態に戻す
  reset() {
    this.inputTarget.value = ""
    this.imageTarget.src   = ""
    this.#hide()
  }

  // ─── private ─────────────────────────────────────────────

  #compress(file) {
    return new Promise((resolve) => {
      const img = new Image()
      const url = URL.createObjectURL(file)
      img.onload = () => {
        URL.revokeObjectURL(url)

        const scale  = Math.min(1, MAX_PX / Math.max(img.width, img.height))
        const canvas = document.createElement("canvas")
        canvas.width  = Math.round(img.width  * scale)
        canvas.height = Math.round(img.height * scale)
        canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height)

        canvas.toBlob(
          (blob) => resolve(new File([blob], file.name.replace(/\.[^.]+$/, ".jpg"), { type: "image/jpeg" })),
          "image/jpeg",
          QUALITY
        )
      }
      img.src = url
    })
  }

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
