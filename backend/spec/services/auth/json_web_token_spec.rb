require "rails_helper"

RSpec.describe Auth::JsonWebToken do
  subject(:codec) { described_class.new(secret: "test-secret", ttl: 1.hour) }

  let(:now) { Time.zone.parse("2026-03-01 09:00:00") }

  describe "#encode / #decode" do
    it "round-trips the subject" do
      token = codec.encode(subject: 42).value

      expect(codec.decode(token)).to include("sub" => "42", "iss" => Auth::JsonWebToken::ISSUER)
    end

    it "reports when the token expires" do
      travel_to(now) do
        expect(codec.encode(subject: 1).expires_at).to eq(now + 1.hour)
      end
    end
  end

  describe "#decode" do
    it "rejects an expired token" do
      token = travel_to(now) { codec.encode(subject: 1).value }

      travel_to(now + 1.hour + 1.second) do
        expect { codec.decode(token) }.to raise_error(described_class::InvalidToken, /expired/i)
      end
    end

    it "rejects a token signed with another secret" do
      forged = described_class.new(secret: "attacker-secret").encode(subject: 1).value

      expect { codec.decode(forged) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects a tampered payload" do
      header, _payload, signature = codec.encode(subject: 1).value.split(".")
      tampered_payload = Base64.urlsafe_encode64({ sub: "999", exp: 1.day.from_now.to_i }.to_json, padding: false)

      expect { codec.decode([ header, tampered_payload, signature ].join(".")) }
        .to raise_error(described_class::InvalidToken)
    end

    it "rejects an unsigned (alg=none) token" do
      unsigned = JWT.encode({ sub: "1", iss: Auth::JsonWebToken::ISSUER }, nil, "none")

      expect { codec.decode(unsigned) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects a token from another issuer" do
      other = JWT.encode({ sub: "1", iss: "someone-else", exp: 1.hour.from_now.to_i }, "test-secret", "HS256")

      expect { codec.decode(other) }.to raise_error(described_class::InvalidToken)
    end

    it "rejects garbage" do
      expect { codec.decode("not-a-jwt") }.to raise_error(described_class::InvalidToken)
    end
  end

  describe ".default_secret" do
    it "prefers JWT_SECRET from the environment" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("JWT_SECRET").and_return("from-env")

      expect(described_class.default_secret).to eq("from-env")
    end

    it "falls back to secret_key_base outside production" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("JWT_SECRET").and_return(nil)

      expect(described_class.default_secret).to eq(Rails.application.secret_key_base)
    end

    it "refuses to fall back in production, so tokens are never signed with a guessable key" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("JWT_SECRET").and_return(nil)
      allow(Rails.env).to receive(:production?).and_return(true)

      expect { described_class.default_secret }.to raise_error(KeyError, /JWT_SECRET must be set/)
    end
  end
end
