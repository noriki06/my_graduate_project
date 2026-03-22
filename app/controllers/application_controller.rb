# ApplicationController
# 全コントローラの基底クラス。
# ロケール設定・Devise のパラメータ設定・デモユーザーチェックなどの共通処理をここに定義する。
class ApplicationController < ActionController::Base
  # モダンなブラウザ（IE非対応など）のみ許可する
  allow_browser versions: :modern

  # 全アクションの前にロケールを日本語に固定する
  before_action :set_locale
  # Devise コントローラのみ、追加パラメータの許可設定を行う
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Devise のフォームに name・birthday カラムを追加するための設定
  # デフォルトでは email と password しか受け付けないため、ここで明示的に許可する
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :birthday ])          # 新規登録時
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :birthday ])   # プロフィール更新時
  end

  # Devise のログイン後リダイレクト先を上書きする
  # 生年月日が未登録なら誕生日入力画面へ → 登録済みならWant一覧へ
  def after_sign_in_path_for(resource)
    resource.birthday.present? ? wants_path : edit_birthday_path
  end

  # デモユーザーによる書き込み操作を禁止するフィルター
  # WantsController の create/update/destroy/achieve/toggle_publish で使用する
  # デモユーザーが操作しようとすると元のページに戻してアラートを表示する
  def check_not_demo
    return unless current_user&.demo?
    redirect_back fallback_location: wants_path,
                  alert: "デモユーザーはこの操作ができません。新規登録してお試しください。"
  end

  private

  # アプリ全体のロケールを日本語（:ja）に固定する
  # これにより Devise のエラーメッセージなども日本語になる
  def set_locale
    I18n.locale = :ja
  end
end
