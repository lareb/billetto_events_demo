module Votes
  class CastVote
    include Command::Executable

    attribute :event_id, :integer
    attribute :user_id, :string
    attribute :direction, :string

    validates :event_id, :user_id, presence: true
    validates :direction, inclusion: { in: %w[up down] }
  end
end
