module Events
  class Service
    include Command::Handler

    handles Events::IngestFromBilletto, :ingest_from_billetto

    def initialize(billetto_adapter = Rails.configuration.billetto)
      @billetto_adapter = billetto_adapter
    end

    private

    attr_reader :billetto_adapter

    def ingest_from_billetto(_command)
      raw_events = billetto_adapter.list_public_events

      raw_events.each { |raw_event| store(raw_event) }
    rescue Billetto::RequestFailed => e
      # A failed sync shouldn't take down the caller (rake task, job, console).
      # Existing events stay as they are and the next run picks up again.
      Rails.logger.error("[Events::Service] Billetto fetch failed: #{e.message}")
      false
    end

    def store(raw_event)
      attrs = Events::EventMapper.call(raw_event)
      return if attrs[:external_id].blank?

      event = Events::Event.find_or_initialize_by(external_id: attrs[:external_id])
      event.assign_attributes(attrs)
      return unless event.changed?

      unless event.save
        Rails.logger.warn("[Events::Service] skipped #{attrs[:external_id]}: #{event.errors.full_messages.join(', ')}")
      end
    end
  end
end
