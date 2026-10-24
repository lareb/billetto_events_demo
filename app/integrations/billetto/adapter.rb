module Billetto
  # Auth is an Api-Keypair header of "<api_id>:<api_secret>", generated under
  # Organiser > Integrate > Developers.
  class Adapter
    def initialize(
      api_id:,
      api_secret:,
      base_url: ENV.fetch("BILLETTO_API_URL", "https://billetto.dk"),
      path: ENV.fetch("BILLETTO_API_PATH", "/api/v3/public/events"),
      per_page: ENV.fetch("BILLETTO_API_LIMIT", 100).to_i,
      # Not a product limit, just a backstop against an infinite loop if
      # Billetto's has_more/next_url ever misbehaves.
      max_events: ENV.fetch("BILLETTO_API_MAX_EVENTS", 5000).to_i,
      connection: nil
    )
      @api_id = api_id
      @api_secret = api_secret
      @path = path
      @per_page = per_page
      @max_events = max_events
      @connection = connection || build_connection(base_url)
    end

    # Follows Billetto's has_more/next_url cursor until it runs out or
    # we hit max_events.
    def list_public_events
      events = []
      next_request = path_with_query(path, limit: per_page)

      while next_request && events.size < max_events
        body = get(next_request)
        events.concat(Array(body["data"]))

        next_request = body["has_more"] && body["next_url"].present? ? request_uri_for(body["next_url"]) : nil
      end

      events.first(max_events)
    end

    private

    attr_reader :api_id, :api_secret, :path, :per_page, :max_events, :connection

    def get(request_uri)
      response = connection.get(request_uri)

      unless response.success?
        raise Billetto::RequestFailed, "Billetto API returned #{response.status}: #{response.body}"
      end

      body = response.body
      body.is_a?(Hash) ? body : { "data" => Array(body) }
    rescue Faraday::Error => e
      raise Billetto::RequestFailed, e.message
    end

    def path_with_query(path, params)
      separator = path.include?("?") ? "&" : "?"
      "#{path}#{separator}#{URI.encode_www_form(params)}"
    end

    # next_url is absolute; pull just the path + query so it still goes
    # through our connection.
    def request_uri_for(absolute_url)
      URI.parse(absolute_url).request_uri
    end

    def build_connection(base_url)
      Faraday.new(url: base_url) do |f|
        f.headers["Api-Keypair"] = "#{api_id}:#{api_secret}"
        f.response :json, content_type: /\bjson$/
        f.adapter Faraday.default_adapter
      end
    end
  end
end
