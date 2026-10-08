Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"
  resources :events, only: [ :index ]
  post "events/:event_id/vote", to: "votes#create", as: :vote_event

  if Rails.configuration.x.clerk_stubbed
    get "test_sign_in/:user_id", to: "test_sessions#create", as: :test_sign_in
    delete "test_sign_out", to: "test_sessions#destroy", as: :test_sign_out
  end
end
