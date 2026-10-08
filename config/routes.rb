Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events, only: [ :index ]
  post "events/:event_id/vote", to: "votes#create", as: :vote_event

  delete "sign_out", to: "sessions#destroy", as: :sign_out

  # Signing in goes through Clerk's hosted pages; this stands in for them when
  # no Clerk keys are configured.
  if Rails.configuration.x.clerk_stubbed
    get "test_sign_in/:user_id", to: "test_sessions#create", as: :test_sign_in
  end
end
