require "rails_helper"

RSpec.describe Insights::Outliers do
  # Five US Senior Software Engineers: 70k, 100k, 100k, 100k, 150k -> median 100k.
  let!(:underpaid) { create_engineer(70_000) }
  let!(:overpaid) { create_engineer(150_000) }

  before { 3.times { create_engineer(100_000) } }

  def create_engineer(amount, country: "US")
    create(:employee, country:, department: "Engineering", job_title: "Senior Software Engineer",
                      current_salary_cents: amount * 100)
  end

  it "lists employees beyond the threshold, furthest from the median first" do
    result = described_class.call(threshold_pct: 20)

    expect(result[:rows].pluck(:employee_id, :deviation_pct)).to eq([ [ overpaid.id, 50.0 ], [ underpaid.id, -30.0 ] ])
    expect(result[:rows].first).to include(peer_median_cents: usd(100_000), peer_count: 5, currency: "USD")
  end

  it "respects a higher threshold" do
    expect(described_class.call(threshold_pct: 40)[:rows].pluck(:employee_id)).to eq([ overpaid.id ])
  end

  it "ignores peer groups smaller than the minimum" do
    [ 50_000, 50_000, 50_000, 500_000 ].each { |amount| create_engineer(amount, country: "CA") }

    expect(described_class.call(threshold_pct: 20)[:rows].pluck(:country).uniq).to eq([ "US" ])
  end

  it "applies country and department filters" do
    expect(described_class.call(country: "GB")[:rows]).to be_empty
    expect(described_class.call(department: "Engineering")[:rows].size).to eq(2)
  end

  it "paginates the results" do
    result = described_class.call(threshold_pct: 20, page: 2, per_page: 1)

    expect(result[:rows].pluck(:employee_id)).to eq([ underpaid.id ])
    expect(result[:meta]).to eq(page: 2, per_page: 1, total: 2, total_pages: 2)
  end

  describe ".threshold_from" do
    it "parses, clamps and defaults the threshold" do
      expect([ described_class.threshold_from("35"), described_class.threshold_from("0"),
               described_class.threshold_from("9999"), described_class.threshold_from("abc") ])
        .to eq([ 35.0, 1, 200, 20 ])
    end
  end
end
