# Requires a valid `Authorization: Bearer <jwt>` header on every action.
# Opt out per action with `skip_before_action :authenticate!`.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :authenticate!
  end

  private

  attr_reader :current_user

  def authenticate!
    @current_user = authenticate_with_http_token { |token, _options| user_from_token(token) }
    return if current_user

    response.headers["WWW-Authenticate"] = 'Bearer realm="api"'
    render_unauthorized
  end

  def user_from_token(token)
    User.find_by(id: token_codec.decode(token)["sub"])
  rescue Auth::JsonWebToken::InvalidToken
    nil
  end

  def token_codec = Auth::JsonWebToken.new
end
