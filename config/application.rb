require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BillettoEventsDemo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Clerk's middleware raises without credentials, even on anonymous
    # requests, so skip it and use a stub session when no keys are set. This
    # has to happen here: by the time config/initializers runs, Clerk's railtie
    # has already decided whether to insert the middleware.
    #
    # The stub signs you in as whoever you ask for, so it must never run in
    # production — missing keys there is a misconfiguration, not a fallback.
    clerk = credentials.clerk || {}
    keys_missing = clerk[:secret_key].blank? || clerk[:publishable_key].blank?

    if keys_missing && Rails.env.production?
      raise "Clerk credentials are missing. Set clerk.publishable_key and clerk.secret_key in credentials."
    end

    config.x.clerk_stubbed = keys_missing
    ENV["CLERK_SKIP_RAILTIE"] = "1" if config.x.clerk_stubbed
  end
end
