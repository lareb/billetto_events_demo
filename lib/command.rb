module Command
  class Error < StandardError; end
  class NotRegistered < Error; end

  # Simple commands that carry their own logic in #call. Nothing to register —
  # the bus validates and runs them directly.
  module Executable
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes
    end

    def validate!
      raise ActiveModel::ValidationError, self unless valid?
    end
  end

  # For commands that need dependencies. `handles Foo, :bar` wires the command
  # to a method on the service.
  module Handler
    extend ActiveSupport::Concern

    class_methods do
      def handles(command_class, method_name)
        handled_commands[command_class] = method_name
        Command.bus.register(command_class, self)
      end

      def handled_commands
        @handled_commands ||= {}
      end
    end

    def call(command)
      method_name = self.class.handled_commands.fetch(command.class) do
        raise NotRegistered, "#{self.class} does not handle #{command.class}"
      end
      send(method_name, command)
    end
  end

  # Mixed into controllers and handlers so they can send commands.
  module BusInjector
    extend ActiveSupport::Concern

    def command_bus
      Command.bus
    end
  end

  class Bus
    def initialize
      @handler_classes = {}
    end

    def register(command_class, handler_class)
      @handler_classes[command_class] = handler_class
    end

    def call(command)
      command.validate! if command.respond_to?(:validate!)

      ActiveSupport::Notifications.instrument("command.billetto_events_demo", command: command.class.name) do
        ActiveRecord::Base.transaction do
          if (handler_class = @handler_classes[command.class])
            handler_class.new.call(command)
          elsif command.respond_to?(:call)
            command.call
          else
            raise NotRegistered, "No handler registered for #{command.class}"
          end
        end
      end
    end
  end

  class << self
    def bus
      @bus ||= Bus.new
    end
  end
end
