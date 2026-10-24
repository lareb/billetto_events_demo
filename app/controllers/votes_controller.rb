class VotesController < ApplicationController
  # We render a plain turbo-frame here, not a turbo-stream, so force html
  # or Turbo's own Accept header makes Rails pick the wrong format.
  before_action { request.format = :html }
  before_action :set_event
  before_action :require_sign_in!

  def create
    command_bus.call(
      Votes::CastVote.new(
        event_id: @event.id,
        user_id: current_user_id,
        direction: params[:direction]
      )
    )

    @event.reload
  rescue ActiveModel::ValidationError => e
    @error = e.model.errors.full_messages.to_sentence
  end

  private

  def set_event
    @event = Events::Event.find(params[:event_id])
  end

  # Renders inline instead of redirecting. fetch() auto-follows a redirect
  # before Turbo gets to see it, so a 3xx here wouldn't reach the user as
  # a real page visit anyway.
  def require_sign_in!
    return if signed_in?

    @error = "Sign in to vote."
    render "votes/create"
  end
end
