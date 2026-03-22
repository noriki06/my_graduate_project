# Users::RegistrationsController
# Devise のデフォルト会員登録コントローラを継承して、
# 登録後・更新後のリダイレクト先やパスワード更新の挙動をカスタマイズする。
class Users::RegistrationsController < Devise::RegistrationsController
  protected

  # 新規会員登録が完了した後のリダイレクト先
  # 誕生日入力画面（オンボーディング）へ遷移させる
  def after_sign_up_path_for(_resource)
    edit_birthday_path
  end

  # メール確認が必要な設定の場合（confirmable）に使われるリダイレクト先
  # 現在 confirmable は未使用だが、将来的に有効化した際のために定義しておく
  def after_inactive_sign_up_path_for(_resource)
    edit_birthday_path
  end

  # アカウント情報（メール・パスワードなど）更新後のリダイレクト先
  # Devise デフォルトではサインアウトが発生するが、Want 一覧に戻すようにする
  def after_update_path_for(_resource)
    wants_path
  end

  # パスワード変更フォームでの更新処理をカスタマイズする
  # パスワード欄が空のままなら、現在のパスワード入力なしで他の情報（名前など）だけ更新できる
  # SNSログインユーザーはパスワードを持たないため、この分岐が重要
  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      # パスワードを変更しない場合：current_password の入力を不要にして更新する
      resource.update_without_password(params.except(:current_password))
    else
      # パスワードを変更する場合：通常の Devise の処理（current_password が必要）
      super
    end
  end
end
