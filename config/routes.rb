Rails.application.routes.draw do
  root "pages#home"

  resource :session
  resources :passwords, param: :token

  resources :games, only: %i[new create show] do
    post :start, on: :member
  end

  resource :player, only: %i[new create edit update] do
    get :new_identity
    post :start_over
  end

  namespace :admin do
    root "home#show"
    resources :cryptics, only: %i[index show update]
    resources :syncs, only: %i[index create]
    resource :scoring, only: %i[show update], controller: "scoring"
    resources :players, only: :index do
      member do
        patch :block
        patch :unblock
      end
      post :reset_leaderboard, on: :collection
    end
    resource :settings, only: %i[show update]
    resources :users, only: %i[index new create edit update] do
      member do
        patch :activate
        patch :deactivate
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
