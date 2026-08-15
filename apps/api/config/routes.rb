Rails.application.routes.draw do
  get "/up", to: "health#show", as: :health_check

  namespace :api do
    namespace :v1 do
      resource :status, only: :show, controller: :status
      resource :catalog, only: :show, controller: :catalogs
      resources :otp_challenges, only: :create, path: "auth/otp/challenges"
      resources :otp_verifications, only: :create, path: "auth/otp/verifications"
    end
  end

  constraints AdminMfaConstraint.new do
    mount GoodJob::Engine => "/admin/jobs"
  end

  if Rails.configuration.x.berufe.environment.name.in?(%w[local test])
    namespace :foundation do
      resources :probe_jobs, only: :create
    end
  end
end
