class VotesController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :require_sign_in!

  def create
    event = Events::Event.find(params[:event_id])

    command_bus.call(
      Votes::CastVote.new(
        event_id: event.id,
        user_id: current_user_id,
        direction: params[:direction]
      )
    )
    redirect_to root_path(anchor: dom_id(event)), notice: "Vote recorded."
  rescue ActiveModel::ValidationError => e
    redirect_to root_path, alert: e.model.errors.full_messages.to_sentence
  end

  private

  def require_sign_in!
    redirect_to root_path, alert: "Sign in to vote." unless signed_in?
  end
end
