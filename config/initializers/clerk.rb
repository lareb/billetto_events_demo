return if Rails.configuration.x.clerk_stubbed

clerk = Rails.application.credentials.clerk || {}

Clerk.configure do |config|
  config.publishable_key = clerk[:publishable_key].presence || ENV.fetch("CLERK_PUBLISHABLE_KEY")
  config.secret_key = clerk[:secret_key].presence || ENV.fetch("CLERK_SECRET_KEY")

  # Clerk's middleware answers some requests with a redirect to its handshake
  # endpoint, which only speaks GET. On a DELETE that redirect is followed with
  # the original method and comes back 405, so sign-out is handled outside it.
  # See SessionsController.
  config.excluded_routes = [ "/sign_out" ]
end
