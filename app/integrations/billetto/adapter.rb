module Billetto
  # Auth is an Api-Keypair header of "<api_id>:<api_secret>", generated under
  # Organiser > Integrate > Developers.
  class Adapter
    def initialize(
      api_id:,
      api_secret:,
      base_url: ENV.fetch("BILLETTO_API_URL", "https://billetto.dk"),
      path: ENV.fetch("BILLETTO_API_PATH", "/api/v3/public/events"),
      connection: nil
    )
      @api_id = api_id
      @api_secret = api_secret
      @path = path
      @connection = connection || build_connection(base_url)
    end

    def list_public_events
      response = connection.get(path)

      unless response.success?
        raise Billetto::RequestFailed, "Billetto API returned #{response.status}: #{response.body}"
      end

      body = response.body
      body = body.is_a?(Hash) ? (body["events"] || body["data"] || []) : Array(body)
      body
    rescue Faraday::Error => e
      raise Billetto::RequestFailed, e.message
    end

    private

    attr_reader :api_id, :api_secret, :path, :connection

    def build_connection(base_url)
      Faraday.new(url: base_url) do |f|
        f.headers["Api-Keypair"] = "#{api_id}:#{api_secret}"
        f.response :json, content_type: /\bjson$/
        f.adapter Faraday.default_adapter
      end
    end
  end
end
