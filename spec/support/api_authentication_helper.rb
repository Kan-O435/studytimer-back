# spec/support/api_authentication_helper.rb (例)
module ApiAuthenticationHelper
  def generate_auth_headers(user)
    # Devise Token Auth の場合、ユーザーをログインさせることでヘッダーが返されます
    post user_session_path, params: { email: user.email, password: user.password }
    response.headers.slice('access-token', 'client', 'uid')
  end
end

RSpec.configure do |config|
  config.include ApiAuthenticationHelper, type: :request
end