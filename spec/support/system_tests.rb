# SLOWMO=0.8 pauses after every click so you can follow a browser spec along.
# Pair it with HEADLESS=false to actually watch it run.
if ENV["SLOWMO"]
  module SlowMoClicks
    def click(...)
      super.tap { sleep ENV["SLOWMO"].to_f }
    end
  end

  Capybara::Node::Element.prepend(SlowMoClicks)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    browser = ENV["HEADLESS"] == "false" ? :chrome : :headless_chrome
    driven_by :selenium, using: browser, screen_size: [ 1400, 1000 ]

    # Run the vote-count read model inline so the page shows the new total on
    # the redirect instead of the test having to poll for it.
    ActiveJob::Base.queue_adapter = :inline
  end

  config.after(:each, type: :system) do
    ActiveJob::Base.queue_adapter = :test
  end
end
