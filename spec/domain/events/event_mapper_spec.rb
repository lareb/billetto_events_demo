require "rails_helper"

RSpec.describe Events::EventMapper do
  it "maps the real Billetto API's shape" do
    raw = {
      "id" => "2036241",
      "title" => "Julebørnesjov",
      "startdate" => "2026-12-23T09:00:00Z",
      "description" => "A Christmas show",
      "image_link" => "https://billetto.imgix.net/example.jpg"
    }

    attrs = described_class.call(raw)

    expect(attrs).to eq(
      external_id: "2036241",
      title: "Julebørnesjov",
      starts_at: "2026-12-23T09:00:00Z",
      description: "A Christmas show",
      image_url: "https://billetto.imgix.net/example.jpg"
    )
  end

  it "falls back to alternate key spellings" do
    raw = {
      "uuid" => "evt_2",
      "name" => "Alt Title",
      "starts_at" => "2026-11-02T18:00:00Z",
      "summary" => "Alt summary",
      "image" => { "url" => "https://example.com/alt.png" }
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
