# Users::OmniauthCallbacksController
# Google・GitHub・LINE によるソーシャルログインのコールバックを処理するコントローラ。
# OmniAuth が SNS との認証を完了させた後、このコントローラに認証情報が渡される。
# Devise の OmniauthCallbacksController を継承して使う。
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # ===== Google ログインのコールバック =====
  def google_oauth2
    handle_auth("Google")
  end

  # ===== GitHub ログインのコールバック =====
  def github
    handle_auth("GitHub")
  end

  # ===== LINE ログインのコールバック =====
  # LINE ログインを使うと line_user_id も自動で保存され、
  # LINEリンクコードなしで通知連携が完了する（User.from_omniauth 内で処理）
  def line
    handle_auth("LINE")
  end

  # ===== 認証失敗・キャンセル時 =====
  # ユーザーが SNS の認証画面でキャンセルしたときにここが呼ばれる
  def failure
    redirect_to root_path, alert: "ログインをキャンセルしました"
  end

  private

  # SNS認証の共通処理
  # request.env["omniauth.auth"] から認証情報を取得し、User.from_omniauth でユーザーを作成/取得する
  def handle_auth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      # DBへの保存が成功している場合はログインしてリダイレクト
      sign_in_and_redirect @user, event: :authentication
      # ブラウザが通常のHTMLリクエストの場合のみフラッシュメッセージを表示する
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    else
      # ユーザーの作成に失敗した場合（バリデーションエラーなど）は新規登録フォームへ
      # 認証情報をセッションに保存してフォームの入力補助に使う
      session["devise.omniauth_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  # ログイン後のリダイレクト先を決定する
  # 生年月日が未設定（初回SNSログイン直後）なら誕生日入力画面へ
  # 登録済みなら Want 一覧へ
  def after_sign_in_path_for(resource)
    resource.birthday.nil? ? edit_birthday_path : wants_path
  end
end
