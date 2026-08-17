Rails.application.routes.draw do
  get "/up", to: "health#show", as: :health_check

  namespace :api do
    namespace :v1 do
      resource :status, only: :show, controller: :status
      resource :catalog, only: :show, controller: :catalogs
      put "professional-registration", to: "professional_registrations#update"
      namespace :professional do
        resource :workspace, only: :show, controller: :workspaces
        resource :profile, only: :update, controller: :profiles
        put "profile/photo", to: "profile_photos#update"
        resources :portfolio_items, only: %i[create destroy], path: "portfolio-items"
        resources :media_uploads, only: %i[create show], path: "media-uploads" do
          member do
            put :content
            post :completion
            post :retry
          end
        end
      end
      resource :session, only: %i[show destroy]
      namespace :admin do
        resource :session, only: :create
        resource :catalog, only: :show
        post "catalog/services", to: "catalog_services#create"
        patch "catalog/services/:id", to: "catalog_services#update"
        put "catalog/services/order", to: "catalog_services#reorder"
        post "catalog/neighborhoods", to: "catalog_neighborhoods#create"
        patch "catalog/neighborhoods/:code", to: "catalog_neighborhoods#update"
        put "catalog/neighborhoods/order", to: "catalog_neighborhoods#reorder"
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
