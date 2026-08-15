Rails.application.routes.draw do
  get "/up", to: "health#show", as: :health_check

  constraints AdminMfaConstraint.new do
    mount GoodJob::Engine => "/admin/jobs"
  end

  if Rails.configuration.x.berufe.environment.name.in?(%w[local test])
    namespace :foundation do
      resources :probe_jobs, only: :create
    end
  end
end
