require "rails_helper"

RSpec.describe Events::Service do
  describe "#ingest_from_billetto" do
    it "creates an Event per record returned by the adapter" do
      adapter = instance_double(Billetto::FakeAdapter, list_public_events: [
        { "id" => "evt_1", "name" => "Meetup", "starts_at" => "2026-11-01T18:00:00Z", "description" => "desc", "image" => { "url" => "https://example.com/a.png" } }
      ])

      described_class.new(adapter).call(Events::IngestFromBilletto.new)

      event = Events::Event.find_by(external_id: "evt_1")
      expect(event).to be_present
      expect(event.title).to eq("Meetup")
    end

    it "updates an existing event instead of duplicating it" do
      create(:event, external_id: "evt_1", title: "Old Title")
      adapter = instance_double(Billetto::FakeAdapter, list_public_events: [
        { "id" => "evt_1", "name" => "New Title", "starts_at" => "2026-11-01T18:00:00Z", "description" => "desc", "image" => nil }
      ])

      expect {
        described_class.new(adapter).call(Events::IngestFromBilletto.new)
      }.not_to change(Events::Event, :count)

      expect(Events::Event.find_by(external_id: "evt_1").title).to eq("New Title")
    end

    it "skips records without an id" do
      adapter = instance_double(Billetto::FakeAdapter, list_public_events: [
        { "name" => "No id event" }
      ])

      expect {
        described_class.new(adapter).call(Events::IngestFromBilletto.new)
      }.not_to change(Events::Event, :count)
    end

    it "logs and moves on when the Billetto API fails" do
      adapter = instance_double(Billetto::FakeAdapter)
      allow(adapter).to receive(:list_public_events).and_raise(Billetto::RequestFailed, "503")
      create(:event, external_id: "evt_existing", title: "Already here")

      expect {
        described_class.new(adapter).call(Events::IngestFromBilletto.new)
      }.not_to raise_error

      expect(Events::Event.find_by(external_id: "evt_existing")).to be_present
    end

    it "skips a record with an unparseable date instead of blowing up" do
      adapter = instance_double(Billetto::FakeAdapter, list_public_events: [
        { "id" => "evt_bad", "name" => "Broken", "starts_at" => "not a date" }
      ])

      expect {
        described_class.new(adapter).call(Events::IngestFromBilletto.new)
      }.not_to change(Events::Event, :count)
    end

    it "is reachable through the command bus" do
      expect {
        Command.bus.call(Events::IngestFromBilletto.new)
      }.to change(Events::Event, :count).by(3) # FakeAdapter's 3 sample events
    end
  end
end
