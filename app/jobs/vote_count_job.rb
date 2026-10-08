# Keeps the VoteCount read model in sync with the vote events. Subscribed in
# lib/application_subscriptions.rb; RES enqueues it after the commit.
class VoteCountJob < ApplicationJob
  prepend RailsEventStore::AsyncHandler

  queue_as :low

  def perform(fact)
    event_id = fact.data.fetch(:event_id)
    previous_direction = fact.data[:previous_direction].presence
    new_direction = fact.is_a?(Votes::EventUpvoted) ? "up" : "down"

    record = VoteCount.find_or_create_by!(event_id: event_id)

    VoteCount.transaction do
      record.lock!
      decrement(record, previous_direction) if previous_direction && previous_direction != new_direction
      increment(record, new_direction)
      record.save!
    end
  end

  private

  def increment(record, direction)
    column = direction == "up" ? :upvotes : :downvotes
    record[column] = record[column].to_i + 1
  end

  def decrement(record, direction)
    column = direction == "up" ? :upvotes : :downvotes
    record[column] = [ record[column].to_i - 1, 0 ].max
  end
end
