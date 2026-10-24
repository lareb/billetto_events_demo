require "rails_helper"

RSpec.describe "Browsing events", type: :system do
  it "loads more events on scroll, with no Previous/Next click needed" do
    create_list(:event, EventsController::PER_PAGE + 5)

    visit root_path

    expect(page).to have_selector(".event", count: EventsController::PER_PAGE)

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

    expect(page).to have_selector(".event", count: EventsController::PER_PAGE + 5)
  end
end
