module Votes
  class Service
    include Command::Handler
    include EventStoreInjector

    handles Votes::CastVote, :cast_vote

    private

    def cast_vote(command)
      vote = Votes::Vote.find_or_initialize_by(event_id: command.event_id, user_id: command.user_id)
      previous_direction = vote.direction
      return if previous_direction == command.direction # same button clicked again: no-op, nothing to publish

      vote.direction = command.direction
      vote.save!

      fact_class = command.direction == "up" ? Votes::EventUpvoted : Votes::EventDownvoted
      fact = fact_class.strict(data: {
        event_id: command.event_id,
        user_id: command.user_id,
        previous_direction: previous_direction.to_s
      })

      event_store.publish(fact, stream_name: fact.stream_names.first)
    end
  end
end
