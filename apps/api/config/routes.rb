Rails.application.routes.draw do
  get "/up", to: "health#show", as: :health_check

  namespace :api do
    namespace :v1 do
      resource :status, only: :show, controller: :status
      resource :catalog, only: :show, controller: :catalogs
      get "locations/states", to: "locations#states"
      get "locations/states/:state_abbreviation/cities", to: "locations#cities"
      get "locations/cities/:city_code/neighborhoods", to: "locations#neighborhoods"
      get "public/search-location", to: "public_search_locations#show"
      get "public/professionals/featured", to: "public_featured_professionals#index"
      post "public/professional-searches", to: "public_professional_searches#create"
      get "public/professional-listings", to: "public_professional_listings#index"
      get "public/service-coverage", to: "public_service_coverage#index"
      get "public/service-demand", to: "public_service_demand#show"
      get "public/professionals/:slug", to: "public_professionals#show"
      post "public/professionals/:id/views", to: "public_professional_views#create"
      get "public/professionals/:id/whatsapp", to: "public_professional_whatsapp#show"
      get "public/profile-photos/:id/image", to: "public_profile_photos#show"
      get "public/portfolio-items/:id/image", to: "public_portfolio_images#show"
      put "professional-registration", to: "professional_registrations#update"
      namespace :professional do
        resource :workspace, only: :show, controller: :workspaces
        resource :profile, only: :update, controller: :profiles
        post "profile/submission", to: "profiles#submission"
        put "profile/photo", to: "profile_photos#update"
        delete "profile/photo", to: "profile_photos#destroy"
        resources :portfolio_items, only: %i[create destroy], path: "portfolio-items"
        resources :verification_requests, only: :create, path: "verification-requests"
        resources :relationship_candidates, only: :index, path: "relationship-candidates"
        resources :customer_candidates, only: :index, path: "customer-candidates"
        resources :customers, only: %i[index show update]
        resources :relationships, only: %i[create destroy]
        post "relationships/:id/response", to: "relationships#respond"
        resources :quotes, only: %i[index create show update] do
          member do
            post :share
            delete :share, action: :revoke_share
          end
        end
        resources :service_jobs, only: %i[index show], path: "service-jobs" do
          member do
            post :request_completion, path: "completion-request"
            post :cancel
          end
        end
        resources :media_uploads, only: %i[create show], path: "media-uploads" do
          member do
            put :content
            post :completion
            post :retry
          end
        end
      end
      resource :session, only: %i[show destroy]
      post "shared-quotes/resolve", to: "shared_quotes#resolve"
      post "shared-quotes/decisions", to: "shared_quotes#decide"
      post "shared-quotes/completions", to: "shared_quotes#complete"
      post "customer-recommendations/resolve", to: "customer_recommendations#resolve"
      post "customer-recommendations", to: "customer_recommendations#create"
      namespace :admin do
        resource :session, only: :create
        resource :catalog, only: :show
        get "reports/growth", to: "reports#growth"
        get "search-audits", to: "search_audits#index"
        get "moderation", to: "moderation#index"
        post "moderation/:target_type/:target_id/decisions", to: "moderation_decisions#create"
        get "moderation/:target_type/:target_id/media", to: "moderation_media#show"
        get "verification-files/:id/content", to: "verification_files#show"
        post "catalog/services", to: "catalog_services#create"
        patch "catalog/services/:id", to: "catalog_services#update"
        put "catalog/services/order", to: "catalog_services#reorder"
      end
      resources :otp_challenges, only: :create, path: "auth/otp/challenges"
      resources :otp_verifications, only: :create, path: "auth/otp/verifications"
    end
  end

  constraints AdminSessionConstraint.new do
    mount GoodJob::Engine => "/admin/jobs"
  end

  if Rails.configuration.x.berufe.environment.name.in?(%w[local test])
    namespace :foundation do
      resources :probe_jobs, only: :create
    end
  end
end
