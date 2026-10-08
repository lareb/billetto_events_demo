require "rails_helper"

RSpec.describe Events::EventMapper do
  it "maps the fake adapter's shape" do
    raw = {
      "id" => "evt_1",
      "name" => "Ruby Meetup",
      "starts_at" => "2026-11-01T18:00:00Z",
      "description" => "A meetup",
      "image" => { "url" => "https://example.com/img.png" }
    }

    attrs = described_class.call(raw)

    expect(attrs).to eq(
      external_id: "evt_1",
      title: "Ruby Meetup",
      starts_at: "2026-11-01T18:00:00Z",
      description: "A meetup",
      image_url: "https://example.com/img.png"
    )
  end

  it "falls back to alternate key spellings" do
    raw = {
      "uuid" => "evt_2",
      "title" => "Alt Title",
      "start_date" => "2026-11-02T18:00:00Z",
      "summary" => "Alt summary",
      "image_url" => "https://example.com/alt.png"
    }

    attrs = described_class.call(raw)

    expect(attrs).to include(
      external_id: "evt_2",
      title: "Alt Title",
      starts_at: "2026-11-02T18:00:00Z",
      description: "Alt summary",
      image_url: "https://example.com/alt.png"
    )
  end
end
