module Auth
  # Encodes and verifies the signed, short-lived access tokens used by the API.
  class JsonWebToken
    ALGORITHM = "HS256".freeze
    ISSUER = "acme-salary-management".freeze
    DEFAULT_TTL = 8.hours

    class InvalidToken < StandardError; end

    IssuedToken = Data.define(:value, :expires_at)

    def self.default_secret
      ENV["JWT_SECRET"].presence ||
        (Rails.env.production? ? raise(KeyError, "JWT_SECRET must be set in production") : Rails.application.secret_key_base)
    end

    def initialize(secret: self.class.default_secret, ttl: DEFAULT_TTL)
      @secret = secret
      @ttl = ttl
    end

    def encode(subject:)
      issued_at = Time.current
      expires_at = issued_at + ttl
      payload = { sub: subject.to_s, iat: issued_at.to_i, exp: expires_at.to_i, iss: ISSUER }

      IssuedToken.new(value: JWT.encode(payload, secret, ALGORITHM), expires_at:)
    end

    # Returns the payload, or raises InvalidToken for anything tampered, expired,
    # malformed or signed with another algorithm/issuer.
    def decode(token)
      payload, _header = JWT.decode(token, secret, true, algorithm: ALGORITHM, iss: ISSUER, verify_iss: true)
      payload
    rescue JWT::DecodeError => e
      raise InvalidToken, e.message
    end

    private

    attr_reader :secret, :ttl
  end
end
