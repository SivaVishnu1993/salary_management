require "rails_helper"

RSpec.describe "Api::V1::Meta" do
  describe "GET /api/v1/meta/filters" do
    def make_request(headers: auth_headers) = get("/api/v1/meta/filters", headers:)

    it_behaves_like "an authenticated endpoint"

    it "returns countries with currencies, departments with job ladders, and the FX version" do
      make_request

      expect(json.dig("data", "countries")).to include("code" => "IN", "name" => "India", "currency" => "INR")
      expect(json.dig("data", "departments").first).to include(
        "name" => "Engineering", "job_titles" => include("name" => "Software Engineer I", "level" => 1)
      )
      expect(json.dig("data", "fx")).to include("version" => 1, "as_of" => "2026-01-01")
    end

    it "is served from config without querying payroll tables" do
      headers = auth_headers

      expect(count_queries { make_request(headers:) }).to eq(1) # the user lookup only
    end
  end
end
