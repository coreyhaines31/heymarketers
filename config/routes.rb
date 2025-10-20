Rails.application.routes.draw do
  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  # Marketer directory
  get "marketers", to: "marketer_profiles#index"
  get "marketers/:id", to: "marketer_profiles#show", as: :marketer

  # Profile management (requires authentication)
  resources :marketer_profiles, except: [:index, :show]
  resources :company_profiles

  # Other resources
  resources :skills, only: :index
end
