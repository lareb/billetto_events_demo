require "rails_helper"

RSpec.describe "Events", type: :request do
  it "lists events with title, date, and description" do
    create(:event, title: "Ruby Meetup", description: "A great meetup")

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ruby Meetup")
    expect(response.body).to include("A great meetup")
  end

  it "shows vote totals from the read model" do
    event = create(:event, title: "Ruby Meetup")
    VoteCount.create!(event: event, upvotes: 5, downvotes: 2)

    get root_path

    expect(response.body).to include("5")
    expect(response.body).to include("2")
  end
end
