Rails.application.routes.draw do
  root 'home#show'

  # circle owner
  get 'invite' => 'subscriptions#new', as: :new_subscription
  post 'invite' => 'subscriptions#create', as: :subscriptions
  delete 'subscriptions/:token' => 'subscriptions#destroy',
    as: :remove_subscription

  # subscriber entry points, kept short for SMS
  get 'p/:token' => 'shares#show', as: :share
  get 's/:token' => 'subscriptions#show', as: :subscription
  post 's/:token/accept' => 'subscriptions#accept',
    as: :accept_subscription
  delete 's/:token' => 'subscriptions#deactivate',
    as: :deactivate_subscription
  resources :posts, only: %i[new create]
  resource :profile, only: %i[edit update]

  get 'signup', to: 'registrations#new'
  post 'signup', to: 'registrations#create'
  resource :session
  resources :passwords, param: :token

  get 'up' => 'rails/health#show', as: :rails_health_check
end
