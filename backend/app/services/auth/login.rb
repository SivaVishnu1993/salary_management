module Auth
  # Exchanges email + password for an access token.
  class Login < ApplicationService
    Session = Data.define(:user, :token)

    def initialize(email:, password:, token_codec: JsonWebToken.new)
      @email = email
      @password = password
      @token_codec = token_codec
    end

    def call
      # authenticate_by hashes the password even when no user matches, so response
      # time does not reveal which emails exist.
      user = User.authenticate_by(email:, password:)
      return Result.failure(:invalid_credentials) if user.nil?

      Result.success(Session.new(user:, token: token_codec.encode(subject: user.id)))
    end

    private

    attr_reader :email, :password, :token_codec
  end
end
