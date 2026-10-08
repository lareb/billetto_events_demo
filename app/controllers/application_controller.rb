class ApplicationController < ActionController::Base
  include Clerk::Authenticatable
  include Command::BusInjector

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :stub_clerk_session if Rails.configuration.x.clerk_stubbed

  helper_method :current_user_id, :signed_in?, :clerk_sign_in_url, :clerk_sign_up_url

  private

  def current_user_id
    clerk.user_id
  end

  def signed_in?
    clerk.user?
  end

  def clerk_sign_in_url
    clerk_portal_url(Rails.application.credentials.dig(:clerk, :sign_in_url))
  end

  def clerk_sign_up_url
    clerk_portal_url(Rails.application.credentials.dig(:clerk, :sign_up_url))
  end

  # Clerk's hosted pages live on another domain, so they need telling where to
  # send the browser back to.
  def clerk_portal_url(url)
    return url if url.blank?

    uri = URI.parse(url)
    uri.query = URI.encode_www_form(URI.decode_www_form(uri.query.to_s) << [ "redirect_url", root_url ])
    uri.to_s
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
