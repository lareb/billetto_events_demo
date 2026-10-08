module Billetto
  # Used in tests, and in development when no API credentials are set, so the
  # app runs without real Billetto access.
  class FakeAdapter
    def list_public_events
      now = Time.current

      [
        {
          "id" => "evt_rails_meetup",
          "name" => "Ruby on Rails Meetup",
          "starts_at" => (now + 7.days).iso8601,
          "description" => "Community meetup for Rails developers.",
          "image" => { "url" => "https://picsum.photos/seed/evt1/600/400" }
        },
        {
          "id" => "evt_es_workshop",
          "name" => "Event-Driven Architecture Workshop",
          "starts_at" => (now + 14.days).iso8601,
          "description" => "Hands-on workshop on event sourcing with Rails Event Store.",
          "image" => { "url" => "https://picsum.photos/seed/evt2/600/400" }
        },
        {
          "id" => "evt_hotwire_night",
          "name" => "Hotwire Hack Night",
          "starts_at" => (now + 21.days).iso8601,
          "description" => "An evening of building reactive UI without writing JS.",
          "image" => { "url" => "https://picsum.photos/seed/evt3/600/400" }
        }
      ]
    end
  end
end
