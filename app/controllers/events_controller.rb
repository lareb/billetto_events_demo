class EventsController < ApplicationController
  PER_PAGE = 6

  def index
    scope = Events::Event.includes(:vote_count).order(starts_at: :asc)
    @total_pages = [ (scope.count / PER_PAGE.to_f).ceil, 1 ].max

    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    @events = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end
end
