Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'

  get "up" => "rails/health#show", as: :rails_health_check

  resources :tasks, only:[:index,:create,:destroy,:update,:show]

  namespace :api do
    namespace :v1 do
      resources :timer_sessions,only: [:index,:create,:show,:update]
    end
  end
end
