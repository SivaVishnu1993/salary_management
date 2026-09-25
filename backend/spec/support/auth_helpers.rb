# Builds request headers carrying a valid access token for `user`.
module AuthHelpers
  def auth_headers(user = create(:user))
    token = Auth::JsonWebToken.new.encode(subject: user.id).value
    { "Authorization" => "Bearer #{token}" }
  end

  def json = response.parsed_body
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
