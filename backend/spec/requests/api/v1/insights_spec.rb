require "rails_helper"

RSpec.describe "Api::V1::Insights" do
  let(:headers) { auth_headers }

  before { create_sample_payroll }

  describe "GET /api/v1/insights/summary" do
    def make_request(headers: self.headers, params: {}) = get("/api/v1/insights/summary", headers:, params:)

    it_behaves_like "an authenticated endpoint"

    it "returns headline numbers in USD" do
      make_request

      expect(json["data"]).to eq("headcount" => 6, "total_payroll_usd_cents" => usd(450_000),
                                 "median_salary_usd_cents" => usd(55_000), "average_salary_usd_cents" => usd(75_000))
    end

    it "accepts lower-case country filters" do
      make_request(params: { country: "us" })

      expect(json.dig("data", "headcount")).to eq(3)
    end

    it "returns 422 for an unknown country" do
      make_request(params: { country: "XX" })

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to eq("code" => "invalid_parameter", "message" => "Unknown country: XX")
    end

    it "returns 422 for an unknown department" do
      make_request(params: { department: "Legal" })

      expect(json.dig("error", "message")).to eq("Unknown department: Legal")
    end

    it "serves repeat requests from the cache" do
      make_request
      queries = count_queries { make_request }

      expect(queries).to eq(1) # the user lookup only
    end
  end

  describe "GET /api/v1/insights/by_country" do
    def make_request(headers: self.headers) = get("/api/v1/insights/by_country", headers:)

    it_behaves_like "an authenticated endpoint"

    it "returns one row per country" do
      make_request

      expect(json["data"].pluck("country")).to eq(%w[US GB IN])
    end
  end

  describe "GET /api/v1/insights/by_department" do
    def make_request(headers: self.headers) = get("/api/v1/insights/by_department", headers:)

    it_behaves_like "an authenticated endpoint"

    it "returns one row per department" do
      make_request

      expect(json["data"].pluck("department", "headcount")).to eq([ [ "Engineering", 4 ], [ "Sales", 2 ] ])
    end
  end

  describe "GET /api/v1/insights/job_titles" do
    def make_request(headers: self.headers, params: { country: "IN" })
      get("/api/v1/insights/job_titles", headers:, params:)
    end

    it_behaves_like "an authenticated endpoint"

    it "returns the pay spread per job title in local currency" do
      make_request

      expect(json["data"]).to include("country" => "IN", "currency" => "INR")
      expect(json.dig("data", "job_titles", 0)).to include("job_title" => "Senior Software Engineer", "median_cents" => 2_000_000_00)
    end

    it "requires a country" do
      make_request(params: {})

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/insights/outliers" do
    def make_request(headers: self.headers, params: {}) = get("/api/v1/insights/outliers", headers:, params:)

    before do
      [ 70_000, 100_000, 100_000, 100_000, 150_000 ].each do |amount|
        create(:employee, country: "CA", department: "Engineering", job_title: "Staff Software Engineer",
                          current_salary_cents: amount * 100)
      end
    end

    it_behaves_like "an authenticated endpoint"

    it "returns paginated outliers with the threshold applied" do
      make_request(params: { threshold_pct: 25, per_page: 1 })

      expect(json["data"]).to include("threshold_pct" => 25.0, "min_peers" => 5)
      expect(json.dig("data", "rows").sole).to include("deviation_pct" => 50.0, "peer_median_cents" => usd(100_000))
      expect(json["meta"]).to eq("page" => 1, "per_page" => 1, "total" => 2, "total_pages" => 2)
    end

    it "defaults the threshold when it is not a number" do
      make_request(params: { threshold_pct: "lots" })

      expect(json.dig("data", "threshold_pct")).to eq(20)
    end
  end
end
