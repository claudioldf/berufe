Rails.application.routes.draw do
  get "/up", to: "health#show", as: :health_check
end
