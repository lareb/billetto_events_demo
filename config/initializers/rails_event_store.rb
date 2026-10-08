Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new

  ApplicationSubscriptions.subscribe!(Rails.configuration.event_store)
end
