Rails.configuration.to_prepare do
  next if Rails.env.test? # config/environments/test.rb wires the FakeAdapter instead

  api_id = Rails.application.credentials.dig(:billetto, :api_id) || ENV["BILLETTO_API_ID"]
  api_secret = Rails.application.credentials.dig(:billetto, :api_secret) || ENV["BILLETTO_API_SECRET"]

  Rails.configuration.billetto =
    if api_id.present? && api_secret.present?
      Billetto::Adapter.new(api_id: api_id, api_secret: api_secret)
    else
      Rails.logger.warn("[Billetto] no API credentials configured, using FakeAdapter (sample events only)")
      Billetto::FakeAdapter.new
    end
end
