require "rails_helper"

RSpec.describe "Api::V1::Auth" do
  let!(:user) { create(:user, name: "Hannah Reyes", email: "hr@acme.test", password: "correct-horse-battery") }

  describe "POST /api/v1/auth/login" do
    it "returns a bearer token and the user for valid credentials" do
      post "/api/v1/auth/login", params: { email: "hr@acme.test", password: "correct-horse-battery" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to include("token_type" => "Bearer", "token" => a_kind_of(String), "expires_at" => a_kind_of(String))
      expect(json.dig("data", "user")).to eq("id" => user.id, "name" => "Hannah Reyes", "email" => "hr@acme.test")
    end

    it "issues a token that authenticates later requests" do
      post "/api/v1/auth/login", params: { email: "hr@acme.test", password: "correct-horse-battery" }, as: :json
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{json.dig('data', 'token')}" }

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 with a generic message for a wrong password" do
      post "/api/v1/auth/login", params: { email: "hr@acme.test", password: "wrong-password" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("code" => "unauthorized", "message" => "Invalid email or password")
    end

    it "returns the same 401 for an unknown email" do
      post "/api/v1/auth/login", params: { email: "ghost@acme.test", password: "whatever" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json.dig("error", "message")).to eq("Invalid email or password")
    end

    it "returns 400 when a credential is missing" do
      post "/api/v1/auth/login", params: { email: "hr@acme.test" }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json.dig("error", "code")).to eq("parameter_missing")
    end
  end

  describe "GET /api/v1/auth/me" do
    it "returns the signed-in user" do
      get "/api/v1/auth/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to eq("id" => user.id, "name" => "Hannah Reyes", "email" => "hr@acme.test")
    end

    it "returns 401 without a token" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to start_with("Bearer")
      expect(json.dig("error", "code")).to eq("unauthorized")
    end

    it "returns 401 for an invalid token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer not-a-jwt" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for an expired token" do
      headers = travel_to(9.hours.ago) { auth_headers(user) }

      get "/api/v1/auth/me", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the token's user no longer exists" do
      headers = auth_headers(user)
      user.destroy!

      get "/api/v1/auth/me", headers: headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
