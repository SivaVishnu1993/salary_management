require "rails_helper"

RSpec.describe "Api::V1::Salaries" do
  let(:headers) { auth_headers }
  let(:employee) { create(:employee, country: "DE", hire_date: Date.new(2022, 1, 1), current_salary_cents: 70_000_00) }

  before do
    travel_to(Date.new(2026, 1, 15))
    create(:salary, employee:, amount_cents: 70_000_00, effective_date: Date.new(2022, 1, 1))
  end

  describe "GET /api/v1/employees/:employee_id/salaries" do
    def make_request(headers: self.headers, params: {})
      get("/api/v1/employees/#{employee.id}/salaries", headers:, params:)
    end

    it_behaves_like "an authenticated endpoint"

    it "returns the history newest first, paginated" do
      create(:salary, employee:, amount_cents: 75_000_00, effective_date: Date.new(2024, 1, 1))

      make_request

      expect(json["data"].pluck("amount_cents")).to eq([ 75_000_00, 70_000_00 ])
      expect(json["data"].first).to include("currency" => "EUR", "effective_date" => "2024-01-01")
      expect(json["meta"]).to include("total" => 2)
    end

    it "returns 404 for an unknown employee" do
      get "/api/v1/employees/0/salaries", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/employees/:employee_id/salaries" do
    let(:payload) { { salary: { amount_cents: 80_000_00, effective_date: "2025-07-01", note: "Promotion" } } }

    def make_request(headers: self.headers, params: payload)
      post("/api/v1/employees/#{employee.id}/salaries", headers:, params:, as: :json)
    end

    it_behaves_like "an authenticated endpoint"

    it "records the change and updates the employee's current salary" do
      make_request

      expect(response).to have_http_status(:created)
      expect(json["data"]).to include("amount_cents" => 80_000_00, "currency" => "EUR", "note" => "Promotion")
      expect(employee.reload.current_salary_cents).to eq(80_000_00)
    end

    it "returns 422 for a future effective date" do
      make_request(params: { salary: { amount_cents: 80_000_00, effective_date: "2027-01-01" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "details", "effective_date")).to eq([ "can't be in the future" ])
    end

    it "returns 422 for an implausibly large amount and leaves pay unchanged" do
      make_request(params: { salary: { amount_cents: 70_000_000_000_00, effective_date: "2025-07-01" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.reload.current_salary_cents).to eq(70_000_00)
    end

    it "returns 422 for a non-positive amount" do
      make_request(params: { salary: { amount_cents: -5, effective_date: "2025-07-01" } })

      expect(json.dig("error", "details")).to have_key("amount_cents")
    end
  end
end
