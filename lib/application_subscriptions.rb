# Registers every domain module's event subscriptions with Rails Event Store.
# New module? Merge its .subscriptions into handlers.
module ApplicationSubscriptions
  class << self
    def handlers
      top_level_subscriptions
        .merge(Events.subscriptions)
        .merge(Votes.subscriptions)
    end

    def top_level_subscriptions
      {}
    end

    def subscribe!(event_store)
      handlers.each do |event_class, subscriber_classes|
        subscriber_classes.each do |subscriber_class|
          event_store.subscribe(subscriber_class, to: [ event_class ])
        end
      end
    end
  end
end
