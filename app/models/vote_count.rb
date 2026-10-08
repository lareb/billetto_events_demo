# Read model. Can be rebuilt from the vote events. See VoteCountJob.
class VoteCount < ApplicationRecord
  self.table_name = "vote_counts"

  belongs_to :event, class_name: "Events::Event"
end
