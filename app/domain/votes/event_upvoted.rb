module Votes
  class EventUpvoted < Fact
    SCHEMA = {
      event_id: Integer,
      user_id: String,
      previous_direction: String
    }.freeze

    def stream_names
      [ "Event$#{data.fetch(:event_id)}" ]
    end
  end
end
