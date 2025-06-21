Rails.application.routes.draw do
  # Devise Token Auth を api/v1/auth にマウント（認証系API）
  mount_devise_token_auth_for 'User', at: 'api/v1/auth', controllers: {
    registrations: 'overrides/registrations'  # サインアップ時のカスタムコントローラ
  }

  # 健康チェック用エンドポイント（例: /up）
  get "up" => "rails/health#show", as: :rails_health_check

  # 認証不要の一般的なタスクAPI
  resources :tasks, only: [:index, :create, :destroy, :update, :show]

  # APIバージョン1のネームスペース
  namespace :api do
    namespace :v1 do
      resources :timer_sessions, only: [:index, :create, :show, :update]
      resources :reviews, only: [:index, :create, :show, :update, :destroy]
      resources :weekly_reports, only: [:index]
    end
  end
end
