Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'api/v1/auth', controllers: {
    registrations: 'overrides/registrations'
  }

  get "up" => "rails/health#show", as: :rails_health_check

  resources :tasks, only:[:index,:create,:destroy,:update,:show]

  namespace :api do
    namespace :v1 do
      resources :timer_sessions,only: [:index,:create,:show,:update]
      resources :reviews, only: [:index, :create, :show, :update, :destroy]
      resources :weekly_reports,only:[:index]
    end
  end
end