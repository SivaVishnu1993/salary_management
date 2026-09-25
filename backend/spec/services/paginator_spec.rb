require "rails_helper"

RSpec.describe Paginator do
  before { create_list(:employee, 5) }

  let(:relation) { Employee.order(:id) }

  it "returns the requested slice with totals" do
    page = described_class.call(relation, PageRequest.new(page: 2, per_page: 2))

    expect(page.records.map(&:id)).to eq(Employee.order(:id).offset(2).limit(2).ids)
    expect(page.meta).to eq(page: 2, per_page: 2, total: 5, total_pages: 3)
  end

  it "returns an empty page past the end instead of raising" do
    page = described_class.call(relation, PageRequest.new(page: 99, per_page: 2))

    expect(page.records).to be_empty
    expect(page.meta).to include(page: 99, total: 5, total_pages: 3)
  end

  it "counts correctly when the relation has a custom select" do
    page = described_class.call(Employee.with_usd_salary.order(:id), PageRequest.new(page: 1, per_page: 10))

    expect(page.meta[:total]).to eq(5)
  end
end
