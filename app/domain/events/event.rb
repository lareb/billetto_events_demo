module Events
  class Event < ApplicationRecord
    self.table_name = "events"

    has_one :vote_count, class_name: "VoteCount", foreign_key: :event_id, inverse_of: :event

    validates :external_id, presence: true, uniqueness: true
    validates :title, presence: true
    validates :starts_at, presence: true
    validate :starts_at_must_be_a_real_date

    def upvotes
      vote_count&.upvotes.to_i
    end

    def downvotes
      vote_count&.downvotes.to_i
    end

    private

    # Billetto sends dates as strings. ActiveRecord turns anything unparseable
    # into nil, so catch that here rather than storing an event with no date.
    def starts_at_must_be_a_real_date
      return if starts_at.present?
      return if starts_at_before_type_cast.blank?

      errors.add(:starts_at, "is not a valid date")
    end
  end
end
