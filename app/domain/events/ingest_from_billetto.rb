module Events
  # Trigger-only command: "go sync events from Billetto now".
  class IngestFromBilletto
    include Command::Executable
  end
end
