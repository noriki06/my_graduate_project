# BirthdaysController
# 新規登録・SNSログイン直後のオンボーディングで生年月日を登録する専用コントローラ。
# 生年月日が登録されていない状態でログイン後は常にここにリダイレクトされる。
# 登録完了後は onboarding/result（ライフゲージ初表示画面）へ遷移する。
class BirthdaysController < ApplicationController
  # ログインしていないユーザーはアクセス不可
  before_action :authenticate_user!
  # すでに生年月日が登録済みの場合はWant一覧に飛ばす（二重登録を防ぐ）
  before_action :redirect_if_birthday_present, only: %i[edit update]

  # ===== 生年月日入力フォームの表示 =====
  # 特に処理は不要（ビューを表示するだけ）
  def edit; end

  # ===== 生年月日の保存 =====
  def update
    date = parsed_birthday  # 入力値を Date オブジェクトに変換する

    unless date
      # パースに失敗した場合（形式が違う、無効な日付など）
      current_user.errors.add(:birthday, "はYYYYMMDD（例: 19900102）で入力してください")
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(birthday: date)
      # 初めてライフゲージが見られる画面（onboarding_result）へ遷移する
      redirect_to onboarding_result_path, notice: "生年月日を登録しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # フォームの入力値を Date オブジェクトに変換する
  # ハイフン・スラッシュなど記号が含まれていても数字のみ抽出して対応する
  # 例: "1990-01-02" → "19900102" → Date.parse → 1990/01/02
  # パースに失敗した場合（存在しない日付など）は nil を返す
  def parsed_birthday
    input = params.dig(:user, :birthday).to_s
    normalized = input.gsub(/[^\d]/, "")  # 数字以外をすべて除去
    return nil if normalized.blank?

    Date.strptime(normalized, "%Y%m%d")
  rescue ArgumentError, TypeError
    nil
  end

  # 生年月日が登録済みの場合はWant一覧に飛ばして重複登録を防ぐ
  def redirect_if_birthday_present
    redirect_to wants_path if current_user.birthday.present?
  end
end
