# Stands in for Clerk's hosted sign-in when no Clerk keys are configured.
# Only routed in that case — see config/routes.rb.
class TestSessionsController < ApplicationController
  def create
    cookies[:test_user_id] = params[:user_id]
    redirect_to root_path
  end

  def destroy
    cookies.delete(:test_user_id)
    redirect_to root_path
  end
end
