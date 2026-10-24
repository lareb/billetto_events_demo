VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Leave Selenium's own traffic to the local chromedriver alone.
  config.ignore_localhost = true

  # Keep the real key pair out of the committed cassette.
  config.filter_sensitive_data("<BILLETTO_API_KEYPAIR>") do
    Rails.application.credentials.dig(:billetto, :api_id) &&
      "#{Rails.application.credentials.dig(:billetto, :api_id)}:#{Rails.application.credentials.dig(:billetto, :api_secret)}"
  end
end
