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
      # The real account this was built against had 1000+ public events. A
      # demo app has no business mirroring the whole catalog, so pagination
      # stops after this many even if Billetto's has_more says there's more.
      max_events: ENV.fetch("BILLETTO_API_MAX_EVENTS", 200).to_i,
      connection: nil
    )
      @api_id = api_id
      @api_secret = api_secret
      @path = path
      @per_page = per_page
      @max_events = max_events
      @connection = connection || build_connection(base_url)
    end

    # Billetto paginates with a cursor: each page reports has_more and a
    # next_url carrying an after=<id> param. Follows it until has_more is
    # false or max_events is hit.
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

    # next_url is an absolute URL; this pulls just the path + query back off
    # it so the request still goes through our existing connection (and its
    # Api-Keypair header).
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
