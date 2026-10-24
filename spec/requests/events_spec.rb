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
    before { create_list(:event, 15) }

    it "shows only a page's worth of events, with a lazy-loading frame for the next page" do
      get root_path

      expect(response.body.scan(/class="event"/).count).to eq(EventsController::PER_PAGE)
      expect(response.body).to include(%(id="events_page_2"))
      expect(response.body).to include(%(src="/events?page=2"))
    end

    it "shows the remaining events on the last page, with no further page to load" do
      get root_path(page: 2)

      expect(response.body.scan(/class="event"/).count).to eq(15 - EventsController::PER_PAGE)
      expect(response.body).not_to include(%(id="events_page_3"))
    end

    it "clamps an out-of-range page instead of erroring" do
      get root_path(page: 999)

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(/class="event"/).count).to eq(15 - EventsController::PER_PAGE)
    end
  end
end
