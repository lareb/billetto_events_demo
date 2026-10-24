return if Rails.configuration.x.clerk_stubbed

clerk = Rails.application.credentials.clerk || {}

Clerk.configure do |config|
  config.publishable_key = clerk[:publishable_key].presence || ENV.fetch("CLERK_PUBLISHABLE_KEY")
  config.secret_key = clerk[:secret_key].presence || ENV.fetch("CLERK_SECRET_KEY")

  # Its handshake redirect only speaks GET, which 405s a DELETE. See SessionsController.
  config.excluded_routes = [ "/sign_out" ]
end
