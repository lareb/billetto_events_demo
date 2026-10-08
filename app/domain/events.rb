# Billetto event ingestion and display. Plain CRUD; the event-sourced part of
# the app lives in app/domain/votes.rb.
module Events
  def self.subscriptions
    {}
  end
end
