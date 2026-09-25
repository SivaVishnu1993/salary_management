require "rails_helper"

RSpec.describe Insights::CacheVersion do
  it "is stable until bumped" do
    first_read = described_class.current

    expect(described_class.current).to eq(first_read)
  end

  it "changes when bumped" do
    before_bump = described_class.current

    described_class.bump!

    expect(described_class.current).not_to eq(before_bump)
  end

  it "is bumped when an employee change is committed" do
    before_change = described_class.current

    create(:employee)

    expect(described_class.current).not_to eq(before_change)
  end
end
