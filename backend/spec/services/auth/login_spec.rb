require "rails_helper"

RSpec.describe Auth::Login do
  let!(:user) { create(:user, email: "hr@acme.test", password: "correct-horse-battery") }

  it "returns the user and a token for valid credentials" do
    result = described_class.call(email: "hr@acme.test", password: "correct-horse-battery")

    expect(result).to be_success
    expect(result.value.user).to eq(user)
    expect(Auth::JsonWebToken.new.decode(result.value.token.value)["sub"]).to eq(user.id.to_s)
  end

  it "matches the email case-insensitively" do
    expect(described_class.call(email: " HR@ACME.TEST ", password: "correct-horse-battery")).to be_success
  end

  it "fails for a wrong password" do
    result = described_class.call(email: "hr@acme.test", password: "wrong-password")

    expect(result).to be_failure
    expect(result.error).to eq(:invalid_credentials)
  end

  it "fails the same way for an unknown email" do
    expect(described_class.call(email: "ghost@acme.test", password: "whatever").error).to eq(:invalid_credentials)
  end

  it "uses the injected token codec" do
    codec = instance_double(Auth::JsonWebToken, encode: :token)

    expect(described_class.call(email: "hr@acme.test", password: "correct-horse-battery", token_codec: codec).value.token)
      .to eq(:token)
  end
end
