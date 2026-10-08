# Voting, event-sourced: each vote is published as a Fact and VoteCountJob
# updates the vote_counts table the listing page reads from.
module Votes
  def self.subscriptions
    {
      Votes::EventUpvoted => [ VoteCountJob ],
      Votes::EventDownvoted => [ VoteCountJob ]
    }
  end
end
