FactoryBot.define do
  factory :event, class: "Events::Event" do
    sequence(:external_id) { |n| "evt_#{n}" }
    title { "Ruby on Rails Meetup" }
    starts_at { 1.week.from_now }
    description { "Community meetup for Rails developers." }
    image_url { "https://picsum.photos/seed/evt/600/400" }
  end
end
