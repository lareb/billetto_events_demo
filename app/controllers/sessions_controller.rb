class SessionsController < ApplicationController
  # Clerk has no hosted sign-out page — the session has to be revoked through
  # the backend API and the cookies cleared here. This route is excluded from
  # Clerk's middleware (config/initializers/clerk.rb), so the session is read
  # straight off the cookie rather than from request.env["clerk"].
  def destroy
    if Rails.configuration.x.clerk_stubbed
      cookies.delete(:test_user_id)
    else
      revoke_clerk_session
      clear_clerk_cookies
    end

    redirect_to root_path, notice: "Signed out."
  end

  private

  def revoke_clerk_session
    session_id = clerk_session_id
    return if session_id.blank?

    Clerk::SDK.new.sessions.revoke(session_id: session_id)
  rescue StandardError => e
    # The cookies are cleared either way, so the user is signed out locally.
    # Worst case the session expires on Clerk's side on its own.
    Rails.logger.warn("[Sessions] could not revoke Clerk session: #{e.message}")
  end

  def clerk_session_id
    token = cookies[Clerk::SESSION_COOKIE]
    return if token.blank?

    sdk = Clerk::SDK.new

    begin
      sdk.verify_token(token)["sid"]
    rescue JWT::DecodeError
      # Session tokens are only good for about a minute, so by the time someone
      # clicks sign out theirs has usually expired. Revoking needs the id, not a
      # currently valid token, and the revoke call is authenticated separately.
      sdk.decode_token(token)["sid"]
    end
  end

  def clear_clerk_cookies
    cookies.delete(Clerk::SESSION_COOKIE)
    cookies.delete(Clerk::CLIENT_UAT_COOKIE)
  end
end
