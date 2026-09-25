require "rails_helper"

RSpec.describe EmployeesQuery do
  let!(:grace) do
    create(:employee, first_name: "Grace", last_name: "Hopper", country: "US", department: "Engineering",
                      job_title: "Staff Software Engineer", hire_date: Date.new(2015, 1, 1), current_salary_cents: usd(250_000))
  end
  let!(:ravi) do
    create(:employee, first_name: "Ravi", last_name: "Kumar", country: "IN", department: "Sales",
                      job_title: "Account Executive", hire_date: Date.new(2020, 1, 1), current_salary_cents: 2_000_000_00)
  end
  let!(:alan) do
    create(:employee, first_name: "Alan", last_name: "Turing", country: "GB", department: "Engineering",
                      job_title: "Senior Software Engineer", hire_date: Date.new(2018, 1, 1), current_salary_cents: 90_000_00)
  end

  before do
    create(:fx_rate, currency: "USD", usd_per_unit: 1)
    create(:fx_rate, currency: "INR", usd_per_unit: BigDecimal("0.012"))
    create(:fx_rate, currency: "GBP", usd_per_unit: BigDecimal("1.27"))
  end

  def ids(params = {}) = described_class.call(params).map(&:id)

  it "defaults to all employees sorted by last name" do
    expect(ids).to eq([ grace.id, ravi.id, alan.id ])
  end

  describe "filters" do
    it "filters by country" do
      expect(ids(country: "gb")).to eq([ alan.id ])
    end

    it "filters by department" do
      expect(ids(department: "Engineering")).to contain_exactly(grace.id, alan.id)
    end

    it "filters by job title" do
      expect(ids(job_title: "Account Executive")).to eq([ ravi.id ])
    end

    it "searches by name" do
      expect(ids(q: "turi")).to eq([ alan.id ])
    end

    it "combines filters with search" do
      expect(ids(department: "Engineering", q: "grace")).to eq([ grace.id ])
      expect(ids(department: "Sales", q: "grace")).to be_empty
    end
  end

  describe "sorting" do
    it "sorts by hire date in either direction" do
      expect(ids(sort: "hire_date")).to eq([ grace.id, alan.id, ravi.id ])
      expect(ids(sort: "hire_date", direction: "desc")).to eq([ ravi.id, alan.id, grace.id ])
    end

    it "sorts by USD-normalized salary across currencies" do
      # 250,000 USD > 114,300 USD (90k GBP) > 24,000 USD (2M INR)
      expect(ids(sort: "salary_usd", direction: "desc")).to eq([ grace.id, alan.id, ravi.id ])
    end

    it "sorts by country code" do
      expect(ids(sort: "country")).to eq([ alan.id, ravi.id, grace.id ])
    end

    it "sorts by employee code" do
      expect(ids(sort: "employee_code", direction: "desc")).to eq([ alan.id, ravi.id, grace.id ])
    end

    it "sorts by department, breaking ties by id" do
      expect(ids(sort: "department")).to eq([ grace.id, alan.id, ravi.id ])
    end

    it "sorts by job title" do
      expect(ids(sort: "job_title")).to eq([ ravi.id, alan.id, grace.id ])
    end

    it "falls back to name for unknown sort keys and directions" do
      expect(ids(sort: "password_digest; DROP TABLE", direction: "sideways")).to eq([ grace.id, ravi.id, alan.id ])
    end

    it "breaks ties by id so pagination is stable" do
      twin = create(:employee, first_name: "Grace", last_name: "Hopper", email: "grace2@acme.test")

      expect(ids(q: "grace hopper")).to eq([ grace.id, twin.id ])
    end
  end

  it "exposes the USD salary on each row" do
    row = described_class.call({ country: "IN" }).first

    expect(row.current_salary_usd_cents).to eq(24_000_00)
  end

  it "composes onto a given base relation" do
    expect(described_class.new({}, relation: Employee.where(id: [ ravi.id, alan.id ])).call.map(&:id))
      .to eq([ ravi.id, alan.id ])
  end
end
