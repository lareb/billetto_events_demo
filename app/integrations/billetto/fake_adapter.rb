module Billetto
  # Used in tests, and in development when no API credentials are set, so the
  # app runs without real Billetto access. Shape matches the real
  # GET /api/v3/public/events response.
  class FakeAdapter
    def list_public_events
      now = Time.current

      [
        {
          "id" => "2036237",
          "title" => "Ruby on Rails Meetup",
          "startdate" => (now + 7.days).iso8601,
          "description" => "Community meetup for Rails developers.",
          "image_link" => "https://picsum.photos/seed/evt1/600/400"
        },
        {
          "id" => "2035806",
          "title" => "Event-Driven Architecture Workshop",
          "startdate" => (now + 14.days).iso8601,
          "description" => "Hands-on workshop on event sourcing with Rails Event Store.",
          "image_link" => "https://picsum.photos/seed/evt2/600/400"
        },
        {
          "id" => "2036240",
          "title" => "Hotwire Hack Night",
          "startdate" => (now + 21.days).iso8601,
          "description" => "An evening of building reactive UI without writing JS.",
          "image_link" => "https://picsum.photos/seed/evt3/600/400"
        }
      ]
    end
  end
end
