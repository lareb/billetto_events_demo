require "rails_helper"

RSpec.describe Events::Event, type: :model do
  it "is valid with title, starts_at and a unique external_id" do
    expect(build(:event)).to be_valid
  end

  it "requires a title" do
    event = build(:event, title: nil)
    expect(event).not_to be_valid
    expect(event.errors[:title]).to include("can't be blank")
  end

  it "requires starts_at" do
    event = build(:event, starts_at: nil)
    expect(event).not_to be_valid
    expect(event.errors[:starts_at]).to include("can't be blank")
  end

  it "rejects a starts_at that isn't a real date" do
    event = build(:event, starts_at: "whenever")
    expect(event).not_to be_valid
    expect(event.errors[:starts_at]).to include("is not a valid date")
  end

  it "requires a unique external_id" do
    create(:event, external_id: "evt_1")
    duplicate = build(:event, external_id: "evt_1")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:external_id]).to include("has already been taken")
  end

  describe "#upvotes / #downvotes" do
    it "default to zero without a vote_count row" do
      event = create(:event)
      expect(event.upvotes).to eq(0)
      expect(event.downvotes).to eq(0)
    end

    it "reflect the associated VoteCount row" do
      event = create(:event)
      VoteCount.create!(event: event, upvotes: 3, downvotes: 1)

      expect(event.reload.upvotes).to eq(3)
      expect(event.downvotes).to eq(1)
    end
  end
end
