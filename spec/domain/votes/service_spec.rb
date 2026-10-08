require "rails_helper"

RSpec.describe Votes::Service do
  let(:event) { create(:event) }

  it "publishes Votes::EventUpvoted on an upvote" do
    expect {
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "up"))
    }.to have_published_fact(Votes::EventUpvoted, event_id: event.id, user_id: "user_1")
  end

  it "publishes Votes::EventDownvoted on a downvote" do
    expect {
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "down"))
    }.to have_published_fact(Votes::EventDownvoted, event_id: event.id, user_id: "user_1")
  end

  it "records one Vote per user per event, updatable rather than duplicated" do
    Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "up"))

    expect {
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "down"))
    }.not_to change(Votes::Vote, :count)

    expect(Votes::Vote.find_by(event: event, user_id: "user_1").direction).to eq("down")
  end

  it "updates the VoteCount read model asynchronously" do
    perform_enqueued_jobs do
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "up"))
    end

    count = VoteCount.find_by(event: event)
    expect(count.upvotes).to eq(1)
    expect(count.downvotes).to eq(0)
  end

  it "moves the vote between buckets when a user switches their vote" do
    perform_enqueued_jobs do
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "up"))
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "down"))
    end

    count = VoteCount.find_by(event: event)
    expect(count.upvotes).to eq(0)
    expect(count.downvotes).to eq(1)
  end

  it "does not inflate the count when the same direction is clicked again" do
    perform_enqueued_jobs do
      3.times do
        Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "up"))
      end
    end

    expect(Votes::Vote.where(event: event, user_id: "user_1").count).to eq(1)
    expect(VoteCount.find_by(event: event).upvotes).to eq(1)
  end

  it "rejects an invalid direction" do
    expect {
      Command.bus.call(Votes::CastVote.new(event_id: event.id, user_id: "user_1", direction: "sideways"))
    }.to raise_error(ActiveModel::ValidationError)
  end
end
