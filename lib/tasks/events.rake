namespace :events do
  desc "Fetch events from the Billetto API and store them"
  task ingest: :environment do
    Command.bus.call(Events::IngestFromBilletto.new)
    puts "Done. #{Events::Event.count} events in the database."
  end
end
