class ApplicationController < ActionController::Base
  include Clerk::Authenticatable
  include Command::BusInjector

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :stub_clerk_session if Rails.configuration.x.clerk_stubbed

  helper_method :current_user_id, :signed_in?

  private

  def current_user_id
    clerk.user_id
  end

  def signed_in?
    clerk.user?
  end

  # Stands in for Clerk when no keys are configured. The cookie is set by
  # TestSessionsController.
  def stub_clerk_session
    request.env["clerk"] = TestClerkProxy.new(cookies[:test_user_id])
  end

  TestClerkProxy = Struct.new(:user_id) do
    def user?
      user_id.present?
    end
  end
  private_constant :TestClerkProxy
end
