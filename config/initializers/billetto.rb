Rails.configuration.to_prepare do
  api_id = Rails.application.credentials.dig(:billetto, :api_id) || ENV["BILLETTO_API_ID"]
  api_secret = Rails.application.credentials.dig(:billetto, :api_secret) || ENV["BILLETTO_API_SECRET"]

  if api_id.present? && api_secret.present?
    Rails.configuration.billetto = Billetto::Adapter.new(api_id: api_id, api_secret: api_secret)
  else
    Rails.logger.warn("[Billetto] no API credentials configured, ingestion will no-op") unless Rails.env.test?
    Rails.configuration.billetto = nil
  end
end
