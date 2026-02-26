import { Controller } from "@hotwired/stimulus"

// ラジオボタンで「目標なし / 年齢で設定 / 日付で設定」を切り替える
export default class extends Controller {
  static targets = ["ageSection", "dateSection", "ageField", "dateField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selected =
      this.element.querySelector('input[name="goal_type"]:checked')?.value ?? "none"

    const showAge  = selected === "age"
    const showDate = selected === "date"

    // セクションの表示/非表示
    this.ageSectionTarget.classList.toggle("hidden", !showAge)
    this.dateSectionTarget.classList.toggle("hidden", !showDate)

    // 非表示の入力は disabled にして submit 時に送信しない
    this.ageFieldTarget.disabled  = !showAge
    this.dateFieldTarget.disabled = !showDate
  }
}
