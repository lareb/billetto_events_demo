# Wrapper around the Billetto public events API. Domain code sees
# Billetto::RequestFailed, never a raw Faraday error.
# https://api.billetto.com/reference/list-public-events
module Billetto
  class Error < StandardError; end
  class RequestFailed < Error; end
end
