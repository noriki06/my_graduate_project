Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  root "pages#top"
  get "pages/top"

  # 公開Want一覧・詳細ページ
  get "public_wants",      to: "wants#public_index",         as: :public_wants
  get "public_wishlist",   to: "wants#public_wishlist_index", as: :public_wishlist
  get "public_wants/:id",  to: "wants#public_show",          as: :public_want

  resources :wants, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      get  :achieve_form
      patch :achieve
      patch :toggle_publish
    end
  end

  # 生年月日登録（オンボーディング）
  resource :birthday, only: [ :edit, :update ]

  # ★ 生年月日登録後の結果画面
  get "onboarding/result", to: "onboarding#result", as: :onboarding_result

  # health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Die With Zero紹介ページ
  get "die_with_zero", to: "pages#die_with_zero", as: :die_with_zero
end
