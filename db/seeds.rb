# Pulls events from Billetto. No-ops if no API credentials are configured.
# Safe to re-run: events are matched on external_id.
Command.bus.call(Events::IngestFromBilletto.new)

puts "Seeded #{Events::Event.count} events."
