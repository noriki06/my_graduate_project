Rails.application.routes.draw do
  # Devise の認証ルーティング（ユーザー登録・ログイン・パスワードリセットなど）
  # 独自コントローラを使うために controllers オプションで上書きしている
  devise_for :users, controllers: {
    registrations: "users/registrations",        # 会員登録後のリダイレクト先を独自制御
    omniauth_callbacks: "users/omniauth_callbacks" # Google / GitHub / LINE などのOAuth認証を処理
  }

  # トップページ（未ログイン向けランディングページ）
  root "pages#top"
  get "pages/top"

  # デモログイン：デモ専用ユーザーとして体験できる機能
  # 投稿・編集はできず、アプリの雰囲気を確認するだけのモード
  post "demo_login", to: "demo_sessions#create", as: :demo_login

  # ===== 公開 Want（やりたいこと）一覧・詳細 =====
  # published: true のWantのみを全ユーザーに公開する
  get    "public_wants",          to: "wants#public_index",         as: :public_wants       # 達成済み公開Want一覧
  get    "public_wishlist",       to: "wants#public_wishlist_index", as: :public_wishlist   # 未達成の公開ウィッシュリスト一覧
  get    "public_wants/:id",      to: "wants#public_show",          as: :public_want        # 公開Want詳細（達成・未達成両対応）

  # ===== いいね機能 =====
  # 公開されたWantに対していいね/取り消しを行う
  # find_or_create_by を使って重複いいねを防いでいる
  post   "public_wants/:id/like", to: "likes#create",               as: :like_want
  delete "public_wants/:id/like", to: "likes#destroy",              as: :unlike_want

  # ===== コメント機能 =====
  # 公開Wantの詳細ページからコメントを投稿・削除できる
  post   "public_wants/:id/comments", to: "comments#create",        as: :want_comments
  delete "comments/:id",              to: "comments#destroy",       as: :comment

  # ===== プライベート Want の CRUD =====
  # ログインユーザー自身のWantを管理する（一覧・詳細・新規・作成・編集・更新・削除）
  resources :wants, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      get  :achieve_form    # 達成記録フォームを表示（達成コメント・日付・画像の入力画面）
      patch :achieve         # 達成を保存する（初回達成 or 思い出メモ更新）
      patch :toggle_publish  # 公開/非公開を1クリックで切り替える
    end
  end

  # ===== AI 5分行動提案 =====
  # POST /ai_suggestion → AiSuggestionsController#create
  # ユーザーのWantをスコアリングで選定し、OpenAI APIで5分でできる行動を提案する
  resource :ai_suggestion, only: [ :create ]

  # ===== LINE通知設定 =====
  # ユーザーが通知の頻度・時刻・曜日を設定する画面
  # generate_line_link_token: LINEとの連携に使う6桁コードを発行する
  # unlink_line: LINE連携を解除する
  resource :notification_setting, only: [ :edit, :update ] do
    collection do
      patch :generate_line_link_token # 6桁のリンクコードを新規発行してLINEに送る用に表示
      patch :unlink_line              # line_user_id と line_link_token をnilにしてLINE連携解除
    end
  end

  # ===== LINE Webhook =====
  # LINEプラットフォームからイベント（メッセージなど）を受け取るエンドポイント
  # 6桁のリンクコードを受信してユーザーとLINEアカウントを紐づける処理を行う
  post "line_webhook", to: "line_webhooks#callback"

  # ===== プロフィール編集 =====
  # 名前・メールアドレス・生年月日・目標寿命（target_age）を変更できる
  resource :profile, only: [ :edit, :update ]

  # ===== 生年月日登録（オンボーディング） =====
  # 新規登録・SNSログイン直後に誕生日を設定させるための専用フロー
  # 生年月日を登録することでライフゲージの計算が有効になる
  resource :birthday, only: [ :edit, :update ]

  # 生年月日登録後に表示する結果画面（ライフゲージをはじめて見せる演出）
  get "onboarding/result", to: "onboarding#result", as: :onboarding_result

  # ===== ヘルスチェック =====
  # Renderなどのホスティングサービスからアプリの死活監視に使われる
  get "up" => "rails/health#show", as: :rails_health_check

  # ===== Cron トリガー =====
  # Google Apps Script（GAS）から毎時呼び出されるエンドポイント
  # X-Cron-Token ヘッダーで認証し、該当ユーザーにLINE通知を送る
  post "cron/notifications", to: "cron#send_notifications"

  # ===== PWA（Progressive Web App）=====
  # スマートフォンのホーム画面に追加したときの挙動を制御するファイル
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # ===== 静的コンテンツページ =====
  get "die_with_zero", to: "pages#die_with_zero", as: :die_with_zero # Die With Zero紹介ページ
  get "terms",   to: "pages#terms",   as: :terms   # 利用規約
  get "privacy", to: "pages#privacy", as: :privacy  # プライバシーポリシー

  # ===== 管理者エリア =====
  # /admin 以下は管理者専用（AdminController で管理者チェックを行う）
  # ユーザー一覧・削除、Want一覧・削除のみ可能
  namespace :admin do
    root "users#index"
    resources :users, only: [ :index, :destroy ]
    resources :wants, only: [ :index, :destroy ]
  end
end
