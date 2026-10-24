class SessionsController < ApplicationController
  # Clerk has no hosted sign-out page, so we revoke it ourselves here.
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

    if session_id.blank?
      Rails.logger.info("[Sessions] no Clerk session cookie to revoke")
      return
    end

    Clerk::SDK.new.sessions.revoke(session_id: session_id)
    Rails.logger.info("[Sessions] revoked Clerk session #{session_id}")
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
      # Tokens expire fast, so this one is likely expired by now. We just
      # need the session id out of it, not a valid signature.
      sdk.decode_token(token)["sid"]
    end
  end

  def clear_clerk_cookies
    cookies.delete(Clerk::SESSION_COOKIE)
    cookies.delete(Clerk::CLIENT_UAT_COOKIE)
  end
end
