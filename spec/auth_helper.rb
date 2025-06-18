module AuthHelper
  def sign_in(user)
    post '/auth/sign_in', params: { email: user.email, password: 'password' }
    response.headers.slice('client', 'access-token', 'uid', 'token-type', 'expiry')
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
