require "rails_helper"

RSpec.describe Insights::JobTitles do
  before { create_sample_payroll }

  it "reports the local-currency pay spread per job title in one country" do
    expect(described_class.call(country: "IN")).to eq(
      country: "IN", currency: "INR",
      job_titles: [
        { department: "Engineering", job_title: "Senior Software Engineer", level: 3, headcount: 2,
          min_cents: 1_000_000_00, median_cents: 2_000_000_00, average_cents: 2_000_000_00, max_cents: 3_000_000_00 }
      ]
    )
  end

  it "still reports a title that has been removed from config, without department or level" do
    allow(Department).to receive(:for_job_title).and_return(nil)

    expect(described_class.call(country: "IN")[:job_titles].sole)
      .to include(job_title: "Senior Software Engineer", department: nil, level: nil, headcount: 2)
  end

  it "orders titles by department then level" do
    create(:employee, country: "US", department: "Engineering", job_title: "Software Engineer I")

    expect(described_class.call(country: "US")[:job_titles].pluck(:job_title))
      .to eq([ "Software Engineer I", "Senior Software Engineer", "Account Executive" ])
  end
end
