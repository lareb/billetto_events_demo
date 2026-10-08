class EventsController < ApplicationController
  def index
    @events = Events::Event.includes(:vote_count).order(starts_at: :asc)
  end
end
