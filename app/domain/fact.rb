# Base class for our domain events. Subclasses declare a SCHEMA and the
# stream(s) they belong to; .strict checks the data against SCHEMA.
class Fact < RubyEventStore::Event
  class InvalidFact < StandardError; end

  def self.strict(data:)
    schema_keys = self::SCHEMA.keys
    data_keys = data.keys
    missing = schema_keys - data_keys
    extra = data_keys - schema_keys

    if missing.any? || extra.any?
      raise InvalidFact, "#{name}: missing keys #{missing.inspect}, unexpected keys #{extra.inspect}"
    end

    new(data: data)
  end

  def stream_names
    raise NotImplementedError, "#{self.class} must implement #stream_names"
  end
end
