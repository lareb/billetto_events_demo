module Votes
  # One row per event + user, with a unique index backing it up. Changing a
  # vote updates this row rather than adding another.
  class Vote < ApplicationRecord
    self.table_name = "votes"

    belongs_to :event, class_name: "Events::Event"

    validates :user_id, presence: true
    validates :direction, inclusion: { in: %w[up down] }
    validates :user_id, uniqueness: { scope: :event_id }
  end
end
