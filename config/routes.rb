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
  get "jobs/:slug", to: "job_listings#show", as: :job, constraints: { slug: /[a-z0-9\-]+/ }

  # Main directory (remove redundant /marketers path)
  get "directory", to: "marketer_profiles#index"

  # Messages and reviews for specific marketer profiles
  resources :marketer_profiles, except: [:index, :show] do
    collection do
      get :check_slug
    end
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

  # Admin namespace
  namespace :admin do
    resources :job_sync, only: [:index, :show] do
      collection do
        post :trigger_sync
      end
    end
  end

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

  # Flexible Programmatic SEO Strategy (removing redundant "marketers")
  # Single dimension pages
  get ":slug", to: "seo#dynamic_page", as: :seo_single,
      constraints: lambda { |req| SeoController.valid_single_slug?(req.params[:slug]) }

  # Two dimension combinations
  get ":slug1/:slug2", to: "seo#dynamic_page", as: :seo_double,
      constraints: lambda { |req| SeoController.valid_double_slugs?(req.params[:slug1], req.params[:slug2]) }

  # Three dimension combinations
  get ":slug1/:slug2/:slug3", to: "seo#dynamic_page", as: :seo_triple,
      constraints: lambda { |req| SeoController.valid_triple_slugs?(req.params[:slug1], req.params[:slug2], req.params[:slug3]) }

  # Four dimension combinations
  get ":slug1/:slug2/:slug3/:slug4", to: "seo#dynamic_page", as: :seo_quadruple,
      constraints: lambda { |req| SeoController.valid_quadruple_slugs?(req.params[:slug1], req.params[:slug2], req.params[:slug3], req.params[:slug4]) }

  # Individual marketer profiles
  get "profile/:slug", to: "marketer_profiles#show", as: :marketer,
      constraints: lambda { |req| MarketerProfile.exists?(slug: req.params[:slug]) }
end
