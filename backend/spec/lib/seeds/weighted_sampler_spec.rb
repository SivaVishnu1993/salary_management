require "rails_helper"

RSpec.describe Seeds::WeightedSampler do
  it "only returns keys with positive weight" do
    sampler = described_class.new({ a: 1, b: 0, c: 1 }, rng: Random.new(1))

    expect(Array.new(200) { sampler.sample }.uniq).to contain_exactly(:a, :c)
  end

  it "samples roughly in proportion to weights" do
    sampler = described_class.new({ heavy: 9, light: 1 }, rng: Random.new(7))
    tally = Array.new(10_000) { sampler.sample }.tally

    expect(tally[:heavy] / 10_000.0).to be_within(0.02).of(0.9)
  end

  it "is reproducible for the same seed" do
    first = described_class.new({ a: 1, b: 2 }, rng: Random.new(3))
    second = described_class.new({ a: 1, b: 2 }, rng: Random.new(3))

    expect(Array.new(50) { first.sample }).to eq(Array.new(50) { second.sample })
  end
end
