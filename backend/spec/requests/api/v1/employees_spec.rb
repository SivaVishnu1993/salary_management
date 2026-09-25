require "rails_helper"

RSpec.describe "Api::V1::Employees" do
  let(:headers) { auth_headers }

  before do
    travel_to(Date.new(2026, 1, 15))
    FxRates::Sync.call
  end

  describe "GET /api/v1/employees" do
    def make_request(params: {}, headers: self.headers) = get("/api/v1/employees", params:, headers:)

    it_behaves_like "an authenticated endpoint"

    it "returns a page of employees with pagination meta" do
      create_list(:employee, 3)

      make_request(params: { per_page: 2 })

      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(2)
      expect(json["meta"]).to eq("page" => 1, "per_page" => 2, "total" => 3, "total_pages" => 2)
    end

    it "serializes local and USD-normalized salary" do
      create(:employee, country: "IN", first_name: "Priya", current_salary_cents: 1_000_000_00)

      make_request

      expect(json["data"].first).to include(
        "full_name" => a_string_starting_with("Priya"), "country" => "IN", "country_name" => "India",
        "current_salary" => { "amount_cents" => 1_000_000_00, "currency" => "INR" },
        "current_salary_usd_cents" => 12_000_00
      )
    end

    it "applies filters, search and sort from the query string" do
      create(:employee, country: "US", department: "Sales", job_title: "Account Executive", last_name: "Zed")
      target = create(:employee, country: "US", department: "Sales", job_title: "Account Executive", last_name: "Abe")
      create(:employee, country: "GB", department: "Sales", job_title: "Account Executive")

      make_request(params: { country: "US", department: "Sales", q: "abe", sort: "name", direction: "asc" })

      expect(json["data"].pluck("id")).to eq([ target.id ])
    end

    it "clamps an oversized per_page and survives a garbage page" do
      create(:employee)

      make_request(params: { per_page: 5_000, page: "banana" })

      expect(response).to have_http_status(:ok)
      expect(json["meta"]).to include("page" => 1, "per_page" => 100)
    end

    it "uses a constant number of queries regardless of page size" do
      create_list(:employee, 2)
      make_request # warm up one-time metadata lookups
      small = count_queries { make_request }
      create_list(:employee, 10)
      large = count_queries { make_request }

      expect(large).to eq(small)
      expect(small).to be <= 3 # user lookup, COUNT, page SELECT
    end
  end

  describe "GET /api/v1/employees/:id" do
    let(:employee) { create(:employee, country: "GB", current_salary_cents: 50_000_00) }

    def make_request(headers: self.headers) = get("/api/v1/employees/#{employee.id}", headers:)

    it_behaves_like "an authenticated endpoint"

    it "returns the employee" do
      make_request

      expect(json["data"]).to include("id" => employee.id, "employee_code" => employee.employee_code,
                                      "current_salary_usd_cents" => 63_500_00)
    end

    it "returns 404 for an unknown id" do
      get "/api/v1/employees/0", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("code" => "not_found", "message" => "Employee not found")
    end
  end

  describe "POST /api/v1/employees" do
    let(:payload) do
      {
        employee: {
          first_name: "Priya", last_name: "Iyer", email: "priya@acme.test", department: "Engineering",
          job_title: "Software Engineer II", country: "IN", hire_date: "2025-03-01",
          salary: { amount_cents: 1_800_000_00, effective_date: "2025-03-01" }
        }
      }
    end

    def make_request(params: payload, headers: self.headers) = post("/api/v1/employees", params:, headers:, as: :json)

    it_behaves_like "an authenticated endpoint"

    it "creates the employee with a first salary record" do
      expect { make_request }.to change(Employee, :count).by(1).and change(Salary, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["data"]).to include("email" => "priya@acme.test", "employee_code" => a_string_starting_with("ACME-"),
                                      "current_salary" => { "amount_cents" => 1_800_000_00, "currency" => "INR" })
    end

    it "returns 422 with field-level details when invalid" do
      payload[:employee].merge!(email: "nope", job_title: "Account Executive")
      payload[:employee][:salary][:amount_cents] = 0

      make_request

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "code")).to eq("validation_failed")
      expect(json.dig("error", "details").keys).to contain_exactly("email", "job_title", "salary.amount_cents")
    end

    it "returns 400 when the employee payload is missing" do
      make_request(params: {})

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee, country: "US") }

    def make_request(params: { employee: { job_title: "Staff Software Engineer" } }, headers: self.headers)
      patch("/api/v1/employees/#{employee.id}", params:, headers:, as: :json)
    end

    it_behaves_like "an authenticated endpoint"

    it "updates profile fields" do
      make_request

      expect(response).to have_http_status(:ok)
      expect(employee.reload.job_title).to eq("Staff Software Engineer")
    end

    it "ignores salary fields (pay changes go through the salaries endpoint)" do
      make_request(params: { employee: { current_salary_cents: 1, job_title: "Staff Software Engineer" } })

      expect(employee.reload.current_salary_cents).not_to eq(1)
    end

    it "returns 422 when the new country does not match the salary currency" do
      make_request(params: { employee: { country: "DE" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig("error", "details", "current_salary_currency")).to eq([ "must be EUR for this country" ])
    end
  end

  describe "DELETE /api/v1/employees/:id" do
    let!(:employee) { create(:employee).tap { |e| create(:salary, employee: e) } }

    def make_request(headers: self.headers) = delete("/api/v1/employees/#{employee.id}", headers:)

    it_behaves_like "an authenticated endpoint"

    it "deletes the employee and their salary history" do
      expect { make_request }.to change(Employee, :count).by(-1).and change(Salary, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
