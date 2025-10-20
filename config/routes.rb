Rails.application.routes.draw do
  get 'dashboard/index'
  get 'dashboard/analytics'
  get 'dashboard/profile_stats'
  get 'dashboard/job_stats'
  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  # Job board - public listings
  get "jobs", to: "job_listings#index"
  get "jobs/:id", to: "job_listings#show", as: :job

  # Marketer directory
  get "marketers", to: "marketer_profiles#index"
  get "marketers/:id", to: "marketer_profiles#show", as: :marketer

  # Messages and reviews for specific marketer profiles
  resources :marketer_profiles, except: [:index, :show] do
    resources :messages, only: [:new, :create]
    resources :reviews do
      member do
        post :vote
      end
    end
  end

  # General message management
  resources :messages, only: [:index, :show] do
    member do
      patch :mark_as_read
    end
  end

  # Company profiles with nested job listings
  resources :company_profiles do
    resources :job_listings, except: [:index, :show]
  end

  # Other resources
  resources :skills, only: :index

  # Notifications
  resources :notifications, only: [:index, :show] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
      get :unread_count
    end
  end

  # Programmatic SEO pages
  get ":skill_slug-marketers", to: "seo#skills", as: :skill_marketers, constraints: { skill_slug: /[a-z0-9\-]+/ }
  get "marketers-in-:location_slug", to: "seo#locations", as: :location_marketers, constraints: { location_slug: /[a-z0-9\-]+/ }
  get ":skill_slug-marketers-in-:location_slug", to: "seo#skill_location", as: :skill_location_marketers, constraints: { skill_slug: /[a-z0-9\-]+/, location_slug: /[a-z0-9\-]+/ }
end
