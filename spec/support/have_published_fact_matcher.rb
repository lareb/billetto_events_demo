# Lightweight stand-in for rails_event_store-rspec's have_published matcher
# (that gem doesn't install cleanly in this sandbox — see README).
RSpec::Matchers.define :have_published_fact do |fact_class, expected_data = {}|
  supports_block_expectations

  match do |block|
    event_store = Rails.configuration.event_store
    before_ids = event_store.read.of_type(fact_class).to_a.map(&:event_id)

    block.call

    @new_facts = event_store.read.of_type(fact_class).to_a.reject { |fact| before_ids.include?(fact.event_id) }
    @new_facts.any? { |fact| expected_data.all? { |key, value| fact.data[key] == value } }
  end

  failure_message do
    "expected a #{fact_class} matching #{expected_data.inspect} to be published, " \
      "but got: #{(@new_facts || []).map(&:data).inspect}"
  end
end
