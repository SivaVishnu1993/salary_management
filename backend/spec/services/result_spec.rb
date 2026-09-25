require "rails_helper"

RSpec.describe Result do
  it "is a success carrying a value" do
    result = described_class.success(42)

    expect(result).to have_attributes(success?: true, failure?: false, value: 42, error: nil)
  end

  it "is a failure carrying an error" do
    result = described_class.failure(:nope)

    expect(result).to have_attributes(success?: false, failure?: true, value: nil, error: :nope)
  end

  it "is immutable" do
    expect(described_class.success(1)).to be_frozen
  end
end
