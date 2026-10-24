require "rails_helper"

RSpec.describe "Voting on an event", type: :system do
  let!(:event) { create(:event, title: "Ruby on Rails Meetup") }

  it "blocks signed-out visitors from voting" do
    visit root_path

    expect(page).to have_content("Ruby on Rails Meetup")
    within("#events_event_#{event.id}") { click_button "▲ 0" }

    within("#events_event_#{event.id}") do
      expect(page).to have_content("Sign in to vote.")
      expect(page).to have_button("▲ 0")
    end
  end

  it "records a signed-in user's vote in place, without navigating away, and signs them out again" do
    sign_in_in_browser("demo-user")
    expect(page).to have_content("demo-user")

    within("#events_event_#{event.id}") { click_button "▲ 0" }
    within("#events_event_#{event.id}") { expect(page).to have_button("▲ 1") }
    expect(page).to have_current_path(root_path) # no redirect, no lost scroll position

    click_button "Sign out"
    expect(page).to have_link("Sign in")
  end

  it "moves the vote across when a user changes their mind" do
    sign_in_in_browser("demo-user")

    within("#events_event_#{event.id}") { click_button "▲ 0" }
    within("#events_event_#{event.id}") { click_button "▼ 0" }

    within("#events_event_#{event.id}") do
      expect(page).to have_button("▲ 0")
      expect(page).to have_button("▼ 1")
    end
  end

  it "counts two users' votes on the same event separately" do
    sign_in_in_browser("user-one")
    within("#events_event_#{event.id}") { click_button "▲ 0" }

    sign_in_in_browser("user-two")
    within("#events_event_#{event.id}") { click_button "▼ 0" }

    within("#events_event_#{event.id}") do
      expect(page).to have_button("▲ 1")
      expect(page).to have_button("▼ 1")
    end
  end
end
