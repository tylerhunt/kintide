Rails.application.routes.draw do
  root 'home#show'

  resources :invitations, only: %i[show new create], param: :token
  post 'invitations/:token/subscription',
    to: 'subscriptions#create', as: :invitation_subscription
  resources :subscriptions, only: :show, param: :token
  resources :posts, only: %i[new create]

  get 'signup', to: 'registrations#new'
  post 'signup', to: 'registrations#create'
  resource :session
  resources :passwords, param: :token

  get 'up' => 'rails/health#show', as: :rails_health_check
end
