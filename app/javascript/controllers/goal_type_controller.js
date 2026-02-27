import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "ageSection", "dateSection",
    "ageField",   "dateField",
    "ageError",   "dateError"
  ]

  connect() {
    // ページロード時（新規・編集どちらも）に正しい表示状態にする
    this.toggle()
  }

  // data-action="change->goal-type#toggle" から呼ばれる
  toggle() {
    const el      = this.element.querySelector('[name="goal_type"]:checked')
    const val     = el ? el.value : "none"
    const showAge  = val === "age"
    const showDate = val === "date"

    // --- 表示切り替え（style.display で確実に制御 ＋ hidden クラスも同期）---
    this._setVisible(this.ageSectionTarget,  showAge)
    this._setVisible(this.dateSectionTarget, showDate)

    // --- disabled を JS 側のみで管理（SSR の disabled は使わない）---
    this.ageFieldTarget.disabled  = !showAge
    this.dateFieldTarget.disabled = !showDate

    // --- 切り替え時にエラーをリセット ---
    if (this.hasAgeErrorTarget)  this.ageErrorTarget.textContent  = ""
    if (this.hasDateErrorTarget) this.dateErrorTarget.textContent = ""
  }

  validateAge() {
    if (!this.hasAgeErrorTarget) return
    const v = this.ageFieldTarget.value.trim()
    const n = parseInt(v, 10)
    if (!v) {
      this.ageErrorTarget.textContent = "年齢を入力してください"
    } else if (!/^\d+$/.test(v) || n < 1 || n > 120) {
      this.ageErrorTarget.textContent = "1〜120 の整数を入力してください"
    } else {
      this.ageErrorTarget.textContent = ""
    }
  }

  validateDate() {
    if (!this.hasDateErrorTarget) return
    const v = this.dateFieldTarget.value
    if (!v) { this.dateErrorTarget.textContent = "日付を選択してください"; return }
    const sel = new Date(v + "T00:00:00")
    const now = new Date(); now.setHours(0, 0, 0, 0)
    this.dateErrorTarget.textContent = sel < now ? "過去の日付は設定できません" : ""
  }

  // ─── ヘルパー ───────────────────────────────────────────────

  _setVisible(el, visible) {
    if (visible) {
      el.style.display = ""       // inline style をクリア
      el.classList.remove("hidden") // Tailwind の hidden も除去
    } else {
      el.style.display = "none"   // inline style で強制非表示
      el.classList.add("hidden")
    }
  }
}
