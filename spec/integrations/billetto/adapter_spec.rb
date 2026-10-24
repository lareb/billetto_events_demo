require "rails_helper"

RSpec.describe Billetto::Adapter do
  subject(:adapter) { described_class.new(api_id: "id123", api_secret: "secret123", base_url: "https://api.billetto.test", path: "/v2/events") }

  it "defaults to the real API's base URL and path" do
    adapter = described_class.new(api_id: "id123", api_secret: "secret123")

    stub_request(:get, "https://billetto.dk/api/v3/public/events")
      .with(headers: { "Api-Keypair" => "id123:secret123" })
      .to_return(status: 200, body: { "data" => [] }.to_json, headers: { "Content-Type" => "application/json" })

    expect(adapter.list_public_events).to eq([])
  end

  it "sends the Api-Keypair header and returns the events array" do
    stub_request(:get, "https://api.billetto.test/v2/events")
      .with(headers: { "Api-Keypair" => "id123:secret123" })
      .to_return(
        status: 200,
        body: { "data" => [ { "id" => "2036241", "title" => "Meetup" } ] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    expect(adapter.list_public_events).to eq([ { "id" => "2036241", "title" => "Meetup" } ])
  end

  it "raises Billetto::RequestFailed on a non-success response" do
    stub_request(:get, "https://api.billetto.test/v2/events").to_return(status: 500, body: "boom")

    expect { adapter.list_public_events }.to raise_error(Billetto::RequestFailed, /500/)
  end

  it "raises Billetto::RequestFailed on a connection error" do
    stub_request(:get, "https://api.billetto.test/v2/events").to_raise(Faraday::ConnectionFailed.new("down"))

    expect { adapter.list_public_events }.to raise_error(Billetto::RequestFailed)
  end
end
