require "rails_helper"

RSpec.describe "Votes", type: :request do
  let(:event) { create(:event) }

  context "when signed out" do
    it "shows an inline error without recording a vote or redirecting" do
      expect {
        post vote_event_path(event_id: event.id, direction: "up")
      }.not_to change(Votes::Vote, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="events_event_#{event.id}"))
      expect(response.body).to include("Sign in to vote.")
    end
  end

  context "when signed in" do
    before { sign_in("user_1") }

    it "records the vote and updates the count in place, with no redirect" do
      perform_enqueued_jobs do
        expect {
          post vote_event_path(event_id: event.id, direction: "up")
        }.to change(Votes::Vote, :count).by(1)
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="events_event_#{event.id}"))
      expect(response.body).to include("▲ 1")
    end

    it "shows an inline error for an invalid direction without raising a 500" do
      post vote_event_path(event_id: event.id, direction: "sideways")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Direction is not included in the list")
      expect(Votes::Vote.count).to eq(0)
    end

    it "404s on a non-existent event instead of a 500" do
      post vote_event_path(event_id: 999_999, direction: "up")

      expect(response).to have_http_status(:not_found)
    end
  end
end
