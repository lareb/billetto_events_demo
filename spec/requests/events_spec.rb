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

  describe "pagination" do
    before { create_list(:event, 8) }

    it "shows only a page's worth of events and links to the next page" do
      get root_path

      expect(response.body.scan(/class="event"/).count).to eq(EventsController::PER_PAGE)
      expect(response.body).to include("Page 1 of 2")
      expect(response.body).to include(%(href="/events?page=2"))
    end

    it "shows the remaining events on the last page with no next link" do
      get root_path(page: 2)

      expect(response.body.scan(/class="event"/).count).to eq(8 - EventsController::PER_PAGE)
      expect(response.body).to include("Page 2 of 2")
      expect(response.body).not_to include(%(href="/events?page=3"))
    end

    it "clamps an out-of-range page instead of erroring" do
      get root_path(page: 999)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Page 2 of 2")
    end
  end
end
