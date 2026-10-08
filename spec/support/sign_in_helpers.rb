# Tests fake the Clerk session with a cookie rather than driving Clerk's hosted
# pages. See ApplicationController#stub_clerk_session.
module SignInHelpers
  # Request specs: cookies are writable directly.
  def sign_in(user_id)
    cookies[:test_user_id] = user_id
  end

  # System specs: the browser has to be on the domain before a cookie will stick.
  def sign_in_in_browser(user_id)
    visit root_path
    page.driver.browser.manage.add_cookie(name: "test_user_id", value: user_id)
    visit root_path
  end
end

RSpec.configure do |config|
  config.include SignInHelpers, type: :request
  config.include SignInHelpers, type: :system
end
