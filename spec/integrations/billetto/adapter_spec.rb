require "rails_helper"

RSpec.describe Billetto::Adapter do
  subject(:adapter) { described_class.new(api_id: "id123", api_secret: "secret123", base_url: "https://api.billetto.test", path: "/v2/events") }

  it "raises Billetto::RequestFailed on a non-success response" do
    stub_request(:get, "https://api.billetto.test/v2/events").to_return(status: 500, body: "boom")

    expect { adapter.list_public_events }.to raise_error(Billetto::RequestFailed, /500/)
  end

  it "raises Billetto::RequestFailed on a connection error" do
    stub_request(:get, "https://api.billetto.test/v2/events").to_raise(Faraday::ConnectionFailed.new("down"))

    expect { adapter.list_public_events }.to raise_error(Billetto::RequestFailed)
  end

  describe "against the real Billetto API", :vcr do
    subject(:adapter) do
      creds = Rails.application.credentials.billetto || { api_id: "id123", api_secret: "secret123" }
      described_class.new(api_id: creds[:api_id], api_secret: creds[:api_secret])
    end

    it "defaults to the real base URL and path, and returns events in the shape EventMapper expects" do
      events = adapter.list_public_events

      expect(events).to be_an(Array)
      expect(events).not_to be_empty
      expect(events.first).to include("id", "title", "startdate", "image_link")
    end
  end
end
