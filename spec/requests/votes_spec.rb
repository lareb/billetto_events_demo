require "rails_helper"

RSpec.describe "Votes", type: :request do
  let(:event) { create(:event) }

  context "when signed out" do
    it "redirects without recording a vote" do
      expect {
        post vote_event_path(event_id: event.id, direction: "up")
      }.not_to change(Votes::Vote, :count)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Sign in to vote.")
    end
  end

  context "when signed in" do
    before { sign_in("user_1") }

    it "records the vote and redirects with a confirmation" do
      expect {
        post vote_event_path(event_id: event.id, direction: "up")
      }.to change(Votes::Vote, :count).by(1)

      expect(response).to redirect_to("#{root_path}#events_event_#{event.id}")
      follow_redirect!
      expect(response.body).to include("Vote recorded.")
    end

    it "rejects an invalid direction without raising a 500" do
      post vote_event_path(event_id: event.id, direction: "sideways")

      expect(response).to redirect_to(root_path)
      expect(Votes::Vote.count).to eq(0)
    end

    it "404s on a non-existent event instead of a 500" do
      post vote_event_path(event_id: 999_999, direction: "up")

      expect(response).to have_http_status(:not_found)
    end
  end
end
