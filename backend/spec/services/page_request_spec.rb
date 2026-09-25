require "rails_helper"

RSpec.describe PageRequest do
  it "parses numeric strings" do
    expect(described_class.from(page: "3", per_page: "50").to_h).to eq(page: 3, per_page: 50)
  end

  it "defaults when values are missing" do
    expect(described_class.from(page: nil, per_page: nil).to_h).to eq(page: 1, per_page: 25)
  end

  it "falls back for non-numeric or non-positive values" do
    expect(described_class.from(page: "abc", per_page: "-5").to_h).to eq(page: 1, per_page: 25)
    expect(described_class.from(page: "0", per_page: "1.5").to_h).to eq(page: 1, per_page: 25)
  end

  it "caps per_page at the maximum" do
    expect(described_class.from(page: 1, per_page: 10_000).per_page).to eq(100)
  end
end
