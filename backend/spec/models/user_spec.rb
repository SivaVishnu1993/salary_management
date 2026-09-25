require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to have_secure_password }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.not_to allow_value("nope").for(:email) }
    it { is_expected.to validate_length_of(:password).is_at_least(User::PASSWORD_MIN_LENGTH) }

    it "requires a unique email regardless of case" do
      create(:user, email: "hr@acme.test")

      expect(validation_errors(build(:user, email: "HR@acme.test"), :email)).to include("has already been taken")
    end
  end

  it "normalizes the email" do
    expect(build(:user, email: "  HR@Acme.Test ").email).to eq("hr@acme.test")
  end
end
