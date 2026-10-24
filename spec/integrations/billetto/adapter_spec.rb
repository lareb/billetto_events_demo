require "rails_helper"

RSpec.describe Billetto::Adapter do
  subject(:adapter) { described_class.new(api_id: "id123", api_secret: "secret123", base_url: "https://api.billetto.test", path: "/v2/events", per_page: 2) }

  it "raises Billetto::RequestFailed on a non-success response" do
    stub_request(:get, "https://api.billetto.test/v2/events?limit=2").to_return(status: 500, body: "boom")

    expect { adapter.list_public_events }.to raise_error(Billetto::RequestFailed, /500/)
  end

  it "raises Billetto::RequestFailed on a connection error" do
    stub_request(:get, "https://api.billetto.test/v2/events?limit=2").to_raise(Faraday::ConnectionFailed.new("down"))

    expect { adapter.list_public_events }.to raise_error(Billetto::RequestFailed)
  end

  describe "pagination" do
    it "follows next_url while has_more is true" do
      stub_request(:get, "https://api.billetto.test/v2/events?limit=2").to_return(
        status: 200,
        body: {
          "data" => [ { "id" => "1" }, { "id" => "2" } ],
          "has_more" => true,
          "next_url" => "https://api.billetto.test/v2/events?limit=2&after=2"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "https://api.billetto.test/v2/events?after=2&limit=2").to_return(
        status: 200,
        body: { "data" => [ { "id" => "3" } ], "has_more" => false }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect(adapter.list_public_events.map { |e| e["id"] }).to eq(%w[1 2 3])
    end

    it "stops at max_events even if Billetto still has more" do
      adapter = described_class.new(api_id: "id123", api_secret: "secret123", base_url: "https://api.billetto.test", path: "/v2/events", per_page: 2, max_events: 3)

      stub_request(:get, "https://api.billetto.test/v2/events?limit=2").to_return(
        status: 200,
        body: {
          "data" => [ { "id" => "1" }, { "id" => "2" } ],
          "has_more" => true,
          "next_url" => "https://api.billetto.test/v2/events?limit=2&after=2"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      stub_request(:get, "https://api.billetto.test/v2/events?after=2&limit=2").to_return(
        status: 200,
        body: {
          "data" => [ { "id" => "3" }, { "id" => "4" } ],
          "has_more" => true,
          "next_url" => "https://api.billetto.test/v2/events?limit=2&after=4"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect(adapter.list_public_events.map { |e| e["id"] }).to eq(%w[1 2 3])
    end

    it "stops after one page when has_more is false" do
      stub_request(:get, "https://api.billetto.test/v2/events?limit=2").to_return(
        status: 200,
        body: { "data" => [ { "id" => "1" } ], "has_more" => false }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

      expect(adapter.list_public_events.map { |e| e["id"] }).to eq(%w[1])
    end
  end

  describe "against the real Billetto API", :vcr do
    subject(:adapter) do
      creds = Rails.application.credentials.billetto || { api_id: "id123", api_secret: "secret123" }
      # per_page smaller than max_events forces a real second request, so
      # this proves next_url-following works against Billetto's actual API,
      # not just that one page came back.
      described_class.new(api_id: creds[:api_id], api_secret: creds[:api_secret], per_page: 10, max_events: 15)
    end

    it "defaults to the real base URL and path, follows pagination, and returns events in the shape EventMapper expects" do
      events = adapter.list_public_events

      expect(events.size).to eq(15)
      expect(events.first).to include("id", "title", "startdate", "image_link")
    end
  end
end
