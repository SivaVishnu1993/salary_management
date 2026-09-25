require "rails_helper"
require Rails.root.join("config/redis_cache")

RSpec.describe Insights::Cached do
  let(:insight) do
    Class.new do
      class << self
        attr_accessor :calls

        def name = "Insights::FakeInsight"

        def call(**params)
          self.calls += 1
          { params:, computed: calls }
        end
      end
      self.calls = 0
    end
  end

  let(:cached) { described_class.new(insight) }

  it "computes once and serves repeat calls from the cache" do
    2.times { cached.call(country: "IN") }

    expect(insight.calls).to eq(1)
  end

  it "caches each parameter combination separately" do
    cached.call(country: "IN")
    cached.call(country: "US")

    expect(insight.calls).to eq(2)
  end

  it "ignores nil params and param order when building keys" do
    expect(cached.key_for(country: "IN", department: nil)).to eq(cached.key_for(country: "IN"))
    expect(cached.key_for(a: 1, b: 2)).to eq(cached.key_for(b: 2, a: 1))
  end

  it "recomputes after the payroll data version is bumped" do
    cached.call
    Insights::CacheVersion.bump!
    cached.call

    expect(insight.calls).to eq(2)
  end

  it "includes the FX table version in the key" do
    expect(described_class.new(insight, fx_version: 7).key_for({})).to include("/fx7/")
  end

  it "invalidates when a salary change is committed" do
    employee = create(:employee, current_salary_cents: usd(100_000))
    create(:salary, employee:, amount_cents: usd(100_000))
    by_country = described_class.new(Insights::ByCountry)
    by_country.call

    Salaries::Change.call(employee:, amount_cents: usd(120_000), effective_date: Date.current)

    expect(by_country.call.first[:total_payroll_cents]).to eq(usd(120_000))
  end

  it "falls back to computing when Redis is unreachable" do
    unreachable = ActiveSupport::Cache::RedisCacheStore.new(**RedisCache.options, url: "redis://127.0.0.1:1/0")

    result = described_class.new(insight, cache: unreachable).call(country: "IN")

    expect(result).to include(computed: 1)
  end
end
